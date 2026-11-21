import type { NextConfig } from "next";
import createNextIntlPlugin from "next-intl/plugin";
import packageJson from "./package.json";

const withNextIntl = createNextIntlPlugin("./i18n/request.ts");

const nextConfig: NextConfig = {
  output: "standalone",
  env: {
    NEXT_PUBLIC_APP_VERSION: packageJson.version,
  },
  experimental: {
    proxyClientMaxBodySize: "50mb",
  },
  rewrites: async () => {
    const serverUrl = process.env.SERVER_URL || "http://127.0.0.1:3001";
    return [
      {
        source: "/api/:path*",
        destination: `${serverUrl}/api/:path*`,
      },
      {
        source: "/uploads/:path*",
        destination: `${serverUrl}/uploads/:path*`,
      },
    ];
  },
};

export default withNextIntl(nextConfig);
