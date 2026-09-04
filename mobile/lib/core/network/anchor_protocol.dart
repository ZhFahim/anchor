/// The API contract this build speaks. Paired with `ANCHOR_PROTOCOL` in
/// `server/src/common/protocol/protocol.constants.ts`.
const int anchorProtocol = 4;

/// Names [anchorProtocol] on every request.
const String anchorProtocolHeader = 'X-Anchor-Protocol';

/// Status the server answers with when it refuses [anchorProtocol].
const int upgradeRequiredStatus = 426;
