-- ==============================================================================
-- Qwenton CommerceOps — Initial PostgreSQL Schema
-- Migration: 001_initial_schema.sql
-- Description: Core relational schema with integer minor currency units (paise),
--              foreign key relationships, and integrity constraints.
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------------------------------------
-- 1. Businesses Table (Tenants)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    preferred_language VARCHAR(10) NOT NULL DEFAULT 'en' CHECK (preferred_language IN ('en', 'hi')),
    whatsapp_number VARCHAR(20) NOT NULL,
    gstin_encrypted TEXT,
    default_shipping_cost_minor INT NOT NULL DEFAULT 6000, -- Default ₹60.00
    default_packaging_cost_minor INT NOT NULL DEFAULT 1500, -- Default ₹15.00
    default_return_rate NUMERIC(5,2) NOT NULL DEFAULT 8.00 CHECK (default_return_rate >= 0 AND default_return_rate <= 100),
    default_rto_rate NUMERIC(5,2) NOT NULL DEFAULT 12.00 CHECK (default_rto_rate >= 0 AND default_rto_rate <= 100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_businesses_owner ON public.businesses(owner_user_id);

-- ------------------------------------------------------------------------------
-- 2. Business Members (RBAC: Owner vs Staff)
-- ------------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('owner', 'staff');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.business_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'staff',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(business_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_business_members_user ON public.business_members(user_id);
CREATE INDEX IF NOT EXISTS idx_business_members_business ON public.business_members(business_id);

-- ------------------------------------------------------------------------------
-- 3. Products Catalogue
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    sku VARCHAR(100),
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    selling_price_minor INT NOT NULL CHECK (selling_price_minor >= 0),
    discount_minor INT NOT NULL DEFAULT 0 CHECK (discount_minor >= 0),
    product_cost_minor INT NOT NULL CHECK (product_cost_minor >= 0), -- Cost of Goods Sold (COGS)
    packaging_cost_minor INT NOT NULL DEFAULT 0 CHECK (packaging_cost_minor >= 0),
    shipping_cost_minor INT NOT NULL DEFAULT 0 CHECK (shipping_cost_minor >= 0),
    payment_fee_rate NUMERIC(6,4) NOT NULL DEFAULT 0.0200 CHECK (payment_fee_rate >= 0), -- e.g. 0.0200 = 2%
    expected_return_rate NUMERIC(5,2) NOT NULL DEFAULT 5.00 CHECK (expected_return_rate >= 0 AND expected_return_rate <= 100),
    expected_rto_rate NUMERIC(5,2) NOT NULL DEFAULT 10.00 CHECK (expected_rto_rate >= 0 AND expected_rto_rate <= 100),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_business ON public.products(business_id);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON public.products(business_id, is_active);

-- ------------------------------------------------------------------------------
-- 4. Product Variants
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL, -- e.g. "Size M / Pink"
    sku VARCHAR(100),
    price_delta_minor INT NOT NULL DEFAULT 0, -- price differential in paise (+/-)
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_product_variants_product ON public.product_variants(product_id);

-- ------------------------------------------------------------------------------
-- 5. Product Images
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_product_images_product ON public.product_images(product_id);

-- ------------------------------------------------------------------------------
-- 6. Storefront Links (Public Shareable Tokens)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.storefront_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    public_token VARCHAR(64) UNIQUE NOT NULL, -- Non-guessable random token
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    expires_at TIMESTAMPTZ,
    views_count INT NOT NULL DEFAULT 0 CHECK (views_count >= 0),
    orders_count INT NOT NULL DEFAULT 0 CHECK (orders_count >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_storefront_links_token ON public.storefront_links(public_token);
CREATE INDEX IF NOT EXISTS idx_storefront_links_business ON public.storefront_links(business_id);

-- ------------------------------------------------------------------------------
-- 7. Customers (Encrypted PII, Multi-Tenant)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone_encrypted TEXT NOT NULL,
    address_encrypted TEXT NOT NULL,
    pincode VARCHAR(10) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(100),
    consent_order_communication BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_customers_business ON public.customers(business_id);

-- ------------------------------------------------------------------------------
-- 8. Orders Table
-- ------------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE payment_method_enum AS ENUM ('upi', 'cod');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status_enum AS ENUM (
        'pending', 
        'paid', 
        'cod_confirmed', 
        'refunded', 
        'failed'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE fulfilment_status_enum AS ENUM (
        'new', 
        'payment_pending', 
        'paid', 
        'cod_confirmed', 
        'packed', 
        'shipped', 
        'delivered', 
        'return_requested', 
        'returned', 
        'rto', 
        'cancelled', 
        'refunded'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id),
    order_number VARCHAR(32) NOT NULL,
    payment_method payment_method_enum NOT NULL,
    payment_status payment_status_enum NOT NULL DEFAULT 'pending',
    fulfilment_status fulfilment_status_enum NOT NULL DEFAULT 'new',
    
    -- Financial line items (Strict Integer Minor Units - Paise)
    subtotal_minor INT NOT NULL CHECK (subtotal_minor >= 0),
    discount_minor INT NOT NULL DEFAULT 0 CHECK (discount_minor >= 0),
    shipping_minor INT NOT NULL DEFAULT 0 CHECK (shipping_minor >= 0),
    payment_fee_minor INT NOT NULL DEFAULT 0 CHECK (payment_fee_minor >= 0),
    product_cost_minor INT NOT NULL CHECK (product_cost_minor >= 0),
    packaging_cost_minor INT NOT NULL DEFAULT 0 CHECK (packaging_cost_minor >= 0),
    expected_return_cost_minor INT NOT NULL DEFAULT 0,
    expected_rto_cost_minor INT NOT NULL DEFAULT 0,
    
    -- Dual Profit Metrics
    estimated_profit_minor INT NOT NULL,
    realised_profit_minor INT, -- Populated upon delivery, return, or settlement
    
    notes TEXT,
    tracking_number VARCHAR(100),
    courier_name VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_business_created ON public.orders(business_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(business_id, fulfilment_status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON public.orders(business_id, payment_status);

-- ------------------------------------------------------------------------------
-- 9. Order Items
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    variant_id UUID REFERENCES public.product_variants(id),
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price_minor INT NOT NULL CHECK (unit_price_minor >= 0),
    unit_cost_minor INT NOT NULL CHECK (unit_cost_minor >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);

-- ------------------------------------------------------------------------------
-- 10. Payment Evidence Table
-- ------------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE evidence_type_enum AS ENUM ('utr', 'screenshot', 'provider_callback');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE review_status_enum AS ENUM ('needs_review', 'verified_by_seller', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.payment_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    type evidence_type_enum NOT NULL,
    reference VARCHAR(100), -- 12-digit UPI UTR or bank reference number
    storage_path TEXT, -- Secure private bucket path (e.g. "evidence/{order_id}/screenshot.jpg")
    review_status review_status_enum NOT NULL DEFAULT 'needs_review',
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_evidence_order ON public.payment_evidence(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_evidence_status ON public.payment_evidence(review_status);

-- ------------------------------------------------------------------------------
-- 11. Order Audit Events
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    actor_user_id UUID REFERENCES auth.users(id),
    event_type VARCHAR(50) NOT NULL, -- e.g. 'status_change', 'cost_update', 'evidence_review'
    old_value_json JSONB,
    new_value_json JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_events_order ON public.order_events(order_id, created_at ASC);
