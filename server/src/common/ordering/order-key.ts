// Order keys are fractional indexes (base62, compared byte-wise). The client
// makes them; the server only checks their shape.
export const ORDER_KEY_PATTERN = /^[0-9A-Za-z]{1,128}$/;

// One drop changes one key; the first drop in custom order places every item.
export const MAX_POSITIONS_PER_REQUEST = 500;
