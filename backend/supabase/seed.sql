-- ==============================================================================
-- Qwenton CommerceOps — Realistic Seed Dataset
-- File: seed.sql
-- Description: Test-drive dataset featuring an Indian social seller
--              ("Chikankari Studio Jaipur"), products, variants, storefront
--              links, and orders representing all lifecycle states.
-- ==============================================================================

-- 1. Create Mock User in auth.users if not present
INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'seller@chikankarijaipur.in',
    crypt('DemoPassword123!', gen_salt('bf')),
    NOW(),
    '{"provider":"phone","providers":["phone"]}',
    '{"name":"Sunita Verma","phone":"+919876543210"}',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- 2. Business Entity
INSERT INTO public.businesses (
    id,
    owner_user_id,
    name,
    preferred_language,
    whatsapp_number,
    default_shipping_cost_minor,
    default_packaging_cost_minor,
    default_return_rate,
    default_rto_rate
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000001',
    'Chikankari Studio Jaipur',
    'hi',
    '+919876543210',
    7000, -- ₹70 default shipping
    2500, -- ₹25 default packaging
    5.00,
    10.00
) ON CONFLICT (id) DO NOTHING;

-- 3. Business Member (Owner)
INSERT INTO public.business_members (
    business_id,
    user_id,
    role
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    '00000000-0000-0000-0000-000000000001',
    'owner'
) ON CONFLICT (business_id, user_id) DO NOTHING;

-- 4. Products
-- Product 1: Hand Embroidered Chikankari Kurti
INSERT INTO public.products (
    id,
    business_id,
    name,
    description,
    sku,
    currency,
    selling_price_minor,
    discount_minor,
    product_cost_minor,
    packaging_cost_minor,
    shipping_cost_minor,
    payment_fee_rate,
    expected_return_rate,
    expected_rto_rate,
    stock_quantity,
    is_active
) VALUES (
    '22222222-2222-2222-2222-222222222221',
    '11111111-1111-1111-1111-111111111111',
    'Hand Embroidered Chikankari Kurti - Pastel Pink',
    'Pure modal cotton fabric with intricate hand embroidery from Lucknow artisans. Breathable, comfortable, and elegant.',
    'CHK-PK-01',
    'INR',
    99900,  -- ₹999.00
    5000,   -- ₹50.00 launch discount
    32000,  -- ₹320.00 COGS
    2500,   -- ₹25.00 packaging
    7000,   -- ₹70.00 shipping
    0.0200, -- 2% payment fee
    5.00,
    10.00,
    45,
    TRUE
) ON CONFLICT (id) DO NOTHING;

-- Product 1 Variants
INSERT INTO public.product_variants (id, product_id, name, sku, price_delta_minor, stock_quantity)
VALUES 
    ('33333333-3333-3333-3333-333333333311', '22222222-2222-2222-2222-222222222221', 'Size: S', 'CHK-PK-S', 0, 10),
    ('33333333-3333-3333-3333-333333333312', '22222222-2222-2222-2222-222222222221', 'Size: M', 'CHK-PK-M', 0, 15),
    ('33333333-3333-3333-3333-333333333313', '22222222-2222-2222-2222-222222222221', 'Size: L', 'CHK-PK-L', 0, 12),
    ('33333333-3333-3333-3333-333333333314', '22222222-2222-2222-2222-222222222221', 'Size: XL', 'CHK-PK-XL', 5000, 8) -- +₹50 for XL
ON CONFLICT (id) DO NOTHING;

-- Product 2: Floral Anarkali Set
INSERT INTO public.products (
    id,
    business_id,
    name,
    description,
    sku,
    currency,
    selling_price_minor,
    discount_minor,
    product_cost_minor,
    packaging_cost_minor,
    shipping_cost_minor,
    payment_fee_rate,
    expected_return_rate,
    expected_rto_rate,
    stock_quantity,
    is_active
) VALUES (
    '22222222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'Pure Cotton Floral Anarkali Kurta Set with Dupatta',
    'Premium mulmul cotton set with hand block print and matching chiffon dupatta.',
    'ANR-FL-02',
    'INR',
    149900, -- ₹1499.00
    0,
    52000,  -- ₹520.00 COGS
    3000,   -- ₹30.00 packaging
    8000,   -- ₹80.00 shipping
    0.0200,
    6.00,
    12.00,
    28,
    TRUE
) ON CONFLICT (id) DO NOTHING;

-- Product 3: Oxidised Silver Jhumkas
INSERT INTO public.products (
    id,
    business_id,
    name,
    description,
    sku,
    currency,
    selling_price_minor,
    discount_minor,
    product_cost_minor,
    packaging_cost_minor,
    shipping_cost_minor,
    payment_fee_rate,
    expected_return_rate,
    expected_rto_rate,
    stock_quantity,
    is_active
) VALUES (
    '22222222-2222-2222-2222-222222222223',
    '11111111-1111-1111-1111-111111111111',
    'Traditional Oxidised Silver Peacock Jhumka',
    'Handcrafted brass oxidised earrings with delicate ghungroos. Lightweight and skin-friendly.',
    'JHM-SL-03',
    'INR',
    34900,  -- ₹349.00
    0,
    8000,   -- ₹80.00 COGS
    1500,   -- ₹15.00 packaging
    5000,   -- ₹50.00 shipping
    0.0200,
    2.00,
    5.00,
    80,
    TRUE
) ON CONFLICT (id) DO NOTHING;

-- 5. Storefront Links
INSERT INTO public.storefront_links (
    id,
    business_id,
    product_id,
    public_token,
    is_active,
    views_count,
    orders_count
) VALUES 
    ('44444444-4444-4444-4444-444444444441', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'chikankari-pink', TRUE, 142, 18),
    ('44444444-4444-4444-4444-444444444442', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'anarkali-set', TRUE, 89, 7),
    ('44444444-4444-4444-4444-444444444443', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222223', 'silver-jhumka', TRUE, 210, 24)
ON CONFLICT (id) DO NOTHING;

-- 6. Customers
INSERT INTO public.customers (
    id,
    business_id,
    name,
    phone_encrypted,
    address_encrypted,
    pincode,
    city,
    state
) VALUES 
    ('55555555-5555-5555-5555-555555555551', '11111111-1111-1111-1111-111111111111', 'Pooja Sharma', 'ENC_9876543201', 'Flat 402, Royal Palms, Vaishali Nagar', '302021', 'Jaipur', 'Rajasthan'),
    ('55555555-5555-5555-5555-555555555552', '11111111-1111-1111-1111-111111111111', 'Priya Patel', 'ENC_9876543202', 'B-12, Shanti Kunj, Navrangpura', '380009', 'Ahmedabad', 'Gujarat'),
    ('55555555-5555-5555-5555-555555555553', '11111111-1111-1111-1111-111111111111', 'Rohan Mehta', 'ENC_9876543203', 'Plot 55, Kalyani Nagar', '411006', 'Pune', 'Maharashtra'),
    ('55555555-5555-5555-5555-555555555554', '11111111-1111-1111-1111-111111111111', 'Ananya Sen', 'ENC_9876543204', '14/A Ballygunge Place', '700019', 'Kolkata', 'West Bengal'),
    ('55555555-5555-5555-5555-555555555555', '11111111-1111-1111-1111-111111111111', 'Vikram Singh', 'ENC_9876543205', 'House 88, Gomti Nagar', '226010', 'Lucknow', 'Uttar Pradesh')
ON CONFLICT (id) DO NOTHING;

-- 7. Orders Covering All Scenarios

-- Scenario 1: UPI Payment Pending with Evidence "Needs Review"
INSERT INTO public.orders (
    id,
    business_id,
    customer_id,
    order_number,
    payment_method,
    payment_status,
    fulfilment_status,
    subtotal_minor,
    discount_minor,
    shipping_minor,
    payment_fee_minor,
    product_cost_minor,
    packaging_cost_minor,
    expected_return_cost_minor,
    expected_rto_cost_minor,
    estimated_profit_minor
) VALUES (
    '66666666-6666-6666-6666-666666666661',
    '11111111-1111-1111-1111-111111111111',
    '55555555-5555-5555-5555-555555555551',
    'QC-20261018-0001',
    'upi',
    'pending',
    'payment_pending',
    99900,
    5000,
    7000,
    1898,
    32000,
    2500,
    2372,
    1400,
    47230 -- Estimated profit ₹472.30
) ON CONFLICT (id) DO NOTHING;

-- Evidence for Order 1
INSERT INTO public.payment_evidence (
    order_id,
    type,
    reference,
    storage_path,
    review_status
) VALUES (
    '66666666-6666-6666-6666-666666666661',
    'screenshot',
    '412984928192',
    'evidence/66666666-6666-6666-6666-666666666661/gpay_payment_slip.jpg',
    'needs_review'
);

-- Scenario 2: COD Confirmed, Packed
INSERT INTO public.orders (
    id,
    business_id,
    customer_id,
    order_number,
    payment_method,
    payment_status,
    fulfilment_status,
    subtotal_minor,
    discount_minor,
    shipping_minor,
    payment_fee_minor,
    product_cost_minor,
    packaging_cost_minor,
    expected_return_cost_minor,
    expected_rto_cost_minor,
    estimated_profit_minor
) VALUES (
    '66666666-6666-6666-6666-666666666662',
    '11111111-1111-1111-1111-111111111111',
    '55555555-5555-5555-5555-555555555552',
    'QC-20261018-0002',
    'cod',
    'cod_confirmed',
    'packed',
    149900,
    0,
    8000,
    0, -- No PG fee for COD
    52000,
    3000,
    4497,
    1920,
    80483
) ON CONFLICT (id) DO NOTHING;

-- Scenario 3: Shipped in transit
INSERT INTO public.orders (
    id,
    business_id,
    customer_id,
    order_number,
    payment_method,
    payment_status,
    fulfilment_status,
    subtotal_minor,
    discount_minor,
    shipping_minor,
    payment_fee_minor,
    product_cost_minor,
    packaging_cost_minor,
    expected_return_cost_minor,
    expected_rto_cost_minor,
    estimated_profit_minor,
    tracking_number,
    courier_name
) VALUES (
    '66666666-6666-6666-6666-666666666663',
    '11111111-1111-1111-1111-111111111111',
    '55555555-5555-5555-5555-555555555553',
    'QC-20261018-0003',
    'upi',
    'paid',
    'shipped',
    99900,
    0,
    7000,
    1998,
    32000,
    2500,
    2497,
    1400,
    52505,
    'DEL198273645IN',
    'Delhivery Surface'
) ON CONFLICT (id) DO NOTHING;

-- Scenario 4: RTO (Failed Delivery - True Loss Visible)
INSERT INTO public.orders (
    id,
    business_id,
    customer_id,
    order_number,
    payment_method,
    payment_status,
    fulfilment_status,
    subtotal_minor,
    discount_minor,
    shipping_minor,
    payment_fee_minor,
    product_cost_minor,
    packaging_cost_minor,
    expected_return_cost_minor,
    expected_rto_cost_minor,
    estimated_profit_minor,
    realised_profit_minor,
    tracking_number,
    courier_name
) VALUES (
    '66666666-6666-6666-6666-666666666664',
    '11111111-1111-1111-1111-111111111111',
    '55555555-5555-5555-5555-555555555554',
    'QC-20261018-0004',
    'cod',
    'failed',
    'rto',
    34900,
    0,
    5000,
    0,
    8000,
    1500,
    349,
    500,
    19551,
    -11500, -- Realised Loss: packaging (₹15) + forward & return shipping (₹100) = -₹115.00
    'BLR88371920IN',
    'BlueDart Express'
) ON CONFLICT (id) DO NOTHING;

-- Scenario 5: Delivered & Settled (Realised Profit Confirmed)
INSERT INTO public.orders (
    id,
    business_id,
    customer_id,
    order_number,
    payment_method,
    payment_status,
    fulfilment_status,
    subtotal_minor,
    discount_minor,
    shipping_minor,
    payment_fee_minor,
    product_cost_minor,
    packaging_cost_minor,
    expected_return_cost_minor,
    expected_rto_cost_minor,
    estimated_profit_minor,
    realised_profit_minor,
    tracking_number,
    courier_name
) VALUES (
    '66666666-6666-6666-6666-666666666665',
    '11111111-1111-1111-1111-111111111111',
    '55555555-5555-5555-5555-555555555555',
    'QC-20261018-0005',
    'upi',
    'paid',
    'delivered',
    99900,
    5000,
    7000,
    1898,
    32000,
    2500,
    0,
    0,
    51502,
    51502, -- Exact realised profit: ₹515.02
    'DEL994821034IN',
    'Delhivery Surface'
) ON CONFLICT (id) DO NOTHING;
