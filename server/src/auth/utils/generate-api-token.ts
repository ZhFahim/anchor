import * as crypto from 'crypto';

export const generateApiToken = () => {
  return crypto.randomBytes(32).toString('hex');
};
