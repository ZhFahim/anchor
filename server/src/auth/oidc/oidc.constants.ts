/**
 * Constants for OIDC module
 */

// Profile image storage
export const UPLOADS_DIR = '/data/uploads/profiles';
export const UPLOADS_PROFILES_PATH = '/uploads/profiles/';

// Standard user fields for OIDC user queries
export const OIDC_USER_SELECT = {
  id: true,
  email: true,
  name: true,
  profileImage: true,
  isAdmin: true,
  status: true,
  createdAt: true,
  updatedAt: true,
} as const;

// Content type to file extension mapping for profile images
export const CONTENT_TYPE_EXT_MAP: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/gif': '.gif',
  'image/webp': '.webp',
};
