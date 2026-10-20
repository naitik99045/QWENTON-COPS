-- ==============================================================================
-- Qwenton CommerceOps — Database Functions & Triggers
-- Migration: 003_functions_and_triggers.sql
-- Description: Business logic triggers for order numbers, audit logging,
--              profit calculations, and timestamp updates.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Automatic Timestamp Update Trigger
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_businesses_updated_at
BEFORE UPDATE ON public.businesses
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_orders_updated_at
BEFORE UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- 2. Human-Friendly Order Number Generator (QC-YYYYMMDD-XXXX)
-- ------------------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS public.order_number_seq START 1;

CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
    date_part TEXT;
    seq_val INT;
BEGIN
    IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
        date_part := TO_CHAR(NOW(), 'YYYYMMDD');
        seq_val := NEXTVAL('public.order_number_seq') % 10000;
        NEW.order_number := 'QC-' || date_part || '-' || LPAD(seq_val::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_order_number
BEFORE INSERT ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.generate_order_number();

-- ------------------------------------------------------------------------------
-- 3. Live Profit Engine Calculation Trigger
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_order_profit_trigger()
RETURNS TRIGGER AS $$
DECLARE
    net_sales INT;
BEGIN
    net_sales := NEW.subtotal_minor - NEW.discount_minor;
    
    -- Ensure estimated profit calculation matches PRD formula
    NEW.estimated_profit_minor := net_sales
        - NEW.product_cost_minor
        - NEW.packaging_cost_minor
        - NEW.shipping_minor
        - NEW.payment_fee_minor
        - NEW.expected_return_cost_minor
        - NEW.expected_rto_cost_minor;

    -- Compute realised profit once final status is attained
    IF NEW.fulfilment_status = 'delivered' THEN
        NEW.realised_profit_minor := net_sales
            - NEW.product_cost_minor
            - NEW.packaging_cost_minor
            - NEW.shipping_minor
            - NEW.payment_fee_minor;
    ELSIF NEW.fulfilment_status = 'rto' THEN
        -- RTO costs seller forward shipping + return logistics + packaging
        NEW.realised_profit_minor := 0 
            - NEW.packaging_cost_minor 
            - (NEW.shipping_minor * 2);
    ELSIF NEW.fulfilment_status = 'returned' THEN
        -- Returned item: seller lost packaging + shipping + reverse pickup
        NEW.realised_profit_minor := 0 
            - NEW.packaging_cost_minor 
            - (NEW.shipping_minor + 5000); -- ~Rs 50 reverse courier
    ELSIF NEW.fulfilment_status = 'cancelled' THEN
        NEW.realised_profit_minor := 0;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_order_profit
BEFORE INSERT OR UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.calculate_order_profit_trigger();

-- ------------------------------------------------------------------------------
-- 4. Order Audit Log Trigger
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.audit_order_changes_trigger()
RETURNS TRIGGER AS $$
DECLARE
    actor UUID;
BEGIN
    actor := auth.uid();

    IF (TG_OP = 'UPDATE') THEN
        IF (OLD.fulfilment_status != NEW.fulfilment_status OR OLD.payment_status != NEW.payment_status) THEN
            INSERT INTO public.order_events (
                order_id,
                actor_user_id,
                event_type,
                old_value_json,
                new_value_json
            ) VALUES (
                NEW.id,
                actor,
                'status_change',
                jsonb_build_object(
                    'fulfilment_status', OLD.fulfilment_status,
                    'payment_status', OLD.payment_status
                ),
                jsonb_build_object(
                    'fulfilment_status', NEW.fulfilment_status,
                    'payment_status', NEW.payment_status
                )
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_audit_order_changes
AFTER UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.audit_order_changes_trigger();
