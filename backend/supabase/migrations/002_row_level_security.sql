-- ==============================================================================
-- Qwenton CommerceOps — Row Level Security (RLS) & Multi-Tenant Protection
-- Migration: 002_row_level_security.sql
-- Description: Enforces strict tenant isolation, staff permission boundaries,
--              and secure public storefront checkout without data leakage.
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.storefront_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_events ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- Helper Security Functions (SECURITY DEFINER to prevent recursion)
-- ------------------------------------------------------------------------------

-- Returns true if current authenticated user belongs to the given business
CREATE OR REPLACE FUNCTION public.is_business_member(target_business_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.business_members
        WHERE business_id = target_business_id
          AND user_id = auth.uid()
    );
$$;

-- Returns true if current authenticated user is an OWNER of the given business
CREATE OR REPLACE FUNCTION public.is_business_owner(target_business_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.business_members
        WHERE business_id = target_business_id
          AND user_id = auth.uid()
          AND role = 'owner'
    );
$$;

-- ------------------------------------------------------------------------------
-- 1. Policies for `businesses`
-- ------------------------------------------------------------------------------
-- Members can view their business profile
CREATE POLICY "Members can view their business"
ON public.businesses
FOR SELECT
TO authenticated
USING (public.is_business_member(id));

-- Users can create a new business (onboarding)
CREATE POLICY "Users can create their own business"
ON public.businesses
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = owner_user_id);

-- Only Owners can update business settings
CREATE POLICY "Only owners can update business settings"
ON public.businesses
FOR UPDATE
TO authenticated
USING (public.is_business_owner(id))
WITH CHECK (public.is_business_owner(id));

-- ------------------------------------------------------------------------------
-- 2. Policies for `business_members`
-- ------------------------------------------------------------------------------
CREATE POLICY "Members can view other members in their business"
ON public.business_members
FOR SELECT
TO authenticated
USING (public.is_business_member(business_id));

CREATE POLICY "Owners can manage members"
ON public.business_members
FOR ALL
TO authenticated
USING (public.is_business_owner(business_id))
WITH CHECK (public.is_business_owner(business_id));

-- ------------------------------------------------------------------------------
-- 3. Policies for `products`
-- ------------------------------------------------------------------------------
-- Direct access to products table is restricted to authenticated business members.
-- Public/anonymous storefront queries MUST use `public_storefront_view` to prevent
-- leakage of COGS (product_cost_minor), packaging, shipping, and expected return rates.
-- ------------------------------------------------------------------------------
CREATE POLICY "Members can manage products"
ON public.products
FOR ALL
TO authenticated
USING (public.is_business_member(business_id))
WITH CHECK (public.is_business_member(business_id));

-- ------------------------------------------------------------------------------
-- 4. Policies for `product_variants` and `product_images`
-- ------------------------------------------------------------------------------
CREATE POLICY "Members can manage variants"
ON public.product_variants
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.products p
        WHERE p.id = product_variants.product_id
          AND public.is_business_member(p.business_id)
    )
);

CREATE POLICY "Public can view variants of active storefront products"
ON public.product_variants
FOR SELECT
TO anon, authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.products p
        JOIN public.storefront_links sl ON sl.product_id = p.id
        WHERE p.id = product_variants.product_id
          AND p.is_active = TRUE
          AND sl.is_active = TRUE
          AND (sl.expires_at IS NULL OR sl.expires_at > NOW())
    )
);

CREATE POLICY "Members can manage images"
ON public.product_images
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.products p
        WHERE p.id = product_images.product_id
          AND public.is_business_member(p.business_id)
    )
);

CREATE POLICY "Public can view images of active storefront products"
ON public.product_images
FOR SELECT
TO anon, authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.products p
        JOIN public.storefront_links sl ON sl.product_id = p.id
        WHERE p.id = product_images.product_id
          AND p.is_active = TRUE
          AND sl.is_active = TRUE
          AND (sl.expires_at IS NULL OR sl.expires_at > NOW())
    )
);

-- ------------------------------------------------------------------------------
-- 5. Policies for `storefront_links`
-- ------------------------------------------------------------------------------
CREATE POLICY "Members can manage storefront links"
ON public.storefront_links
FOR ALL
TO authenticated
USING (public.is_business_member(business_id))
WITH CHECK (public.is_business_member(business_id));

CREATE POLICY "Public can view active storefront tokens"
ON public.storefront_links
FOR SELECT
TO anon, authenticated
USING (
    is_active = TRUE 
    AND (expires_at IS NULL OR expires_at > NOW())
);

-- ------------------------------------------------------------------------------
-- 6. Policies for `customers`
-- ------------------------------------------------------------------------------
CREATE POLICY "Members can view and manage customers"
ON public.customers
FOR ALL
TO authenticated
USING (public.is_business_member(business_id))
WITH CHECK (public.is_business_member(business_id));

-- Public customer creation during checkout
CREATE POLICY "Public checkout can insert customer"
ON public.customers
FOR INSERT
TO anon, authenticated
WITH CHECK (TRUE);

-- ------------------------------------------------------------------------------
-- 7. Policies for `orders` & `order_items`
-- ------------------------------------------------------------------------------
CREATE POLICY "Members can view and manage orders"
ON public.orders
FOR ALL
TO authenticated
USING (public.is_business_member(business_id))
WITH CHECK (public.is_business_member(business_id));

-- Public customer checkout creates an order
CREATE POLICY "Public checkout can create order"
ON public.orders
FOR INSERT
TO anon, authenticated
WITH CHECK (TRUE);

CREATE POLICY "Members can manage order items"
ON public.order_items
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_items.order_id
          AND public.is_business_member(o.business_id)
    )
);

CREATE POLICY "Public checkout can insert order items"
ON public.order_items
FOR INSERT
TO anon, authenticated
WITH CHECK (TRUE);

-- ------------------------------------------------------------------------------
-- 8. Policies for `payment_evidence` & `order_events`
-- ------------------------------------------------------------------------------
CREATE POLICY "Members can view and update payment evidence"
ON public.payment_evidence
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = payment_evidence.order_id
          AND public.is_business_member(o.business_id)
    )
);

CREATE POLICY "Public customer can upload payment evidence"
ON public.payment_evidence
FOR INSERT
TO anon, authenticated
WITH CHECK (
    review_status = 'needs_review' -- Customer uploads are ALWAYS forced into 'needs_review'
);

CREATE POLICY "Members can view order audit events"
ON public.order_events
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = order_events.order_id
          AND public.is_business_member(o.business_id)
    )
);

CREATE POLICY "System and members can insert audit events"
ON public.order_events
FOR INSERT
TO authenticated, anon
WITH CHECK (TRUE);

-- ------------------------------------------------------------------------------
-- 9. Secure Public View for Storefront
-- Excludes all internal costs, margins, and return rates from public access
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.public_storefront_view AS
SELECT 
    p.id AS product_id,
    p.name,
    p.description,
    p.currency,
    p.selling_price_minor,
    p.discount_minor,
    p.stock_quantity,
    sl.public_token,
    sl.business_id,
    b.name AS business_name,
    b.whatsapp_number AS seller_whatsapp
FROM public.products p
JOIN public.storefront_links sl ON sl.product_id = p.id
JOIN public.businesses b ON b.id = p.business_id
WHERE p.is_active = TRUE
  AND sl.is_active = TRUE
  AND (sl.expires_at IS NULL OR sl.expires_at > NOW());

-- Revoke direct table select on internal products table from anonymous public users
REVOKE SELECT ON public.products FROM anon;

-- Grant selective read on public_storefront_view
GRANT SELECT ON public.public_storefront_view TO anon, authenticated;

