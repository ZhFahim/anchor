import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
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

export default nextConfig;
