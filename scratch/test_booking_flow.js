const BASE_URL = 'http://127.0.0.1:4500/api/v1';

async function runAudit() {
  console.log('=== STARTING COMPLETE BOOKING FLOW API AUDIT ===\n');

  // 1. Get Categories
  let res = await fetch(`${BASE_URL}/service-categories`);
  let data = await res.json();
  console.log('1. GET /service-categories:', res.status, data.success ? `Found ${data.data.length} categories` : data.message);

  // 2. Get Vendors (with lat/lng)
  res = await fetch(`${BASE_URL}/discovery/vendors?lat=12.9716&lng=77.5946`);
  data = await res.json();
  console.log('2. GET /discovery/vendors:', res.status, data.success ? `Found ${data.data?.length || 0} vendors` : data.message);
  let vendorId = data.data && data.data.length > 0 ? data.data[0].id : '11111111-1111-4111-8111-111111111111';

  // 3. Get Vendor Details & Services
  res = await fetch(`${BASE_URL}/discovery/vendors/${vendorId}`);
  data = await res.json();
  console.log(`3. GET /discovery/vendors/${vendorId}:`, res.status, data.success ? `Vendor details & ${data.data?.services?.length || 0} services fetched` : data.message);

  const vendorServiceId = data.data?.services?.[0]?.service_id;
  const garmentTypeId = data.data?.services?.[0]?.garment_type_id;

  // 4. Send OTP
  res = await fetch(`${BASE_URL}/auth/send-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone: '9876543222' })
  });
  data = await res.json();
  console.log('4. POST /auth/send-otp:', res.status, data.success ? `Challenge: ${data.data?.challenge_id}, OTP: ${data.data?.otp}` : data.message);

  const { challenge_id, otp } = data.data;

  // 5. Verify OTP
  res = await fetch(`${BASE_URL}/auth/verify-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ phone: '9876543222', otp: otp || '573155', challenge_id })
  });
  data = await res.json();
  console.log('5. POST /auth/verify-otp:', res.status, data.success ? `Token issued for User: ${data.data?.user?.id}` : data.message);

  const token = data.data.accessToken;
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  };

  // 6. Pickup Slots
  const nextDate = '2026-07-04';
  res = await fetch(`${BASE_URL}/vendors/${vendorId}/pickup-slots?date=${nextDate}`, { headers });
  data = await res.json();
  console.log(`6. GET /vendors/${vendorId}/pickup-slots:`, res.status, data.success ? `Found ${data.data?.length || 0} pickup slots` : data.message);
  const slotId = data.data && data.data.length > 0 ? data.data[0].id : null;

  // 7. Add Address (checking both snake_case and camelCase compatibility)
  res = await fetch(`${BASE_URL}/addresses`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      label: 'Home',
      addressLine1: '100 Feet Road, Indiranagar',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560038',
      lat: 12.9716,
      lng: 77.5946,
      isDefault: true
    })
  });
  data = await res.json();
  console.log('7. POST /addresses:', res.status, data.success ? `Address saved: ${data.data?.id}` : JSON.stringify(data));
  const addressId = data.data?.id;

  // 8. Generate Quote
  res = await fetch(`${BASE_URL}/quotes`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      vendor_id: vendorId,
      service_id: vendorServiceId,
      garment_lines: [
        { garment_type_id: garmentTypeId, quantity: 2 }
      ]
    })
  });
  data = await res.json();
  console.log('8. POST /quotes:', res.status, data.success ? `Quote generated: ${data.data?.quote_id}, Estimate: ${data.data?.estimate_paise} paise` : JSON.stringify(data));
  const quoteId = data.data?.quote_id || data.data?.quoteId;

  // 8.5 Hold Slot
  res = await fetch(`${BASE_URL}/slot-holds`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      vendor_id: vendorId,
      slot_id: slotId,
      date: nextDate,
      quote_id: quoteId
    })
  });
  data = await res.json();
  console.log('8.5 POST /slot-holds:', res.status, data.success ? `Slot hold created: ${data.data?.id}` : JSON.stringify(data));

  // 9. Prepare Order Draft
  res = await fetch(`${BASE_URL}/orders/prepare`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      quote_id: quoteId,
      address_id: addressId,
      slot_id: slotId
    })
  });
  data = await res.json();
  console.log('9. POST /orders/prepare:', res.status, data.success ? `Order Draft prepared: ${data.data?.order_draft_id}, Payable: ${data.data?.payable_amount_paise} paise` : JSON.stringify(data));
  const orderDraftId = data.data?.order_draft_id || data.data?.orderDraftId;

  // 10. Create Razorpay Payment Order
  res = await fetch(`${BASE_URL}/payments/create-order`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      order_draft_id: orderDraftId
    })
  });
  data = await res.json();
  console.log('10. POST /payments/create-order:', res.status, data.success ? `Razorpay Order: ${data.data?.razorpayOrderId}` : JSON.stringify(data));
  const razorpayOrderId = data.data?.razorpayOrderId;

  // 11. Verify Payment
  res = await fetch(`${BASE_URL}/payments/verify`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: 'pay_test_123456789',
      razorpaySignature: 'mock_signature_for_dev_mode',
      order_draft_id: orderDraftId
    })
  });
  data = await res.json();
  console.log('11. POST /payments/verify:', res.status, data.success ? `Payment Verified successfully` : JSON.stringify(data));

  // 11.5 Place Order From Draft
  res = await fetch(`${BASE_URL}/orders`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      order_draft_id: orderDraftId
    })
  });
  data = await res.json();
  console.log('11.5 POST /orders (placeOrderFromDraft):', res.status, data.success ? `Order Placed: ${data.data?.order?.id || data.data?.order?.orderNumber}` : JSON.stringify(data));
  const orderId = data.data?.order?.id;

  // 12. Orders List
  res = await fetch(`${BASE_URL}/orders`, { headers });
  data = await res.json();
  console.log('12. GET /orders:', res.status, data.success ? `Orders fetched: ${data.data?.length}` : JSON.stringify(data));

  // 13. Order Details
  if (orderId) {
    res = await fetch(`${BASE_URL}/orders/${orderId}`, { headers });
    data = await res.json();
    console.log(`13. GET /orders/${orderId}:`, res.status, data.success ? `Order details fetched successfully` : JSON.stringify(data));

    // 14. Order Invoice
    res = await fetch(`${BASE_URL}/orders/${orderId}/invoice`, { headers });
    console.log(`14. GET /orders/${orderId}/invoice:`, res.status, res.headers.get('content-type'));

    // 15. Order OTP
    res = await fetch(`${BASE_URL}/orders/${orderId}/otp?purpose=PICKUP`, { headers });
    data = await res.json();
    console.log(`15. GET /orders/${orderId}/otp?purpose=PICKUP:`, res.status, data.success ? `OTP fetched: ${data.data?.otp || data.data?.otpCode}` : JSON.stringify(data));
  }
}

runAudit().catch(console.error);
