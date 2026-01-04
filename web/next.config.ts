import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  rewrites: async () => {
    return [
      {
        source: "/api/:path*",
        destination: process.env.SERVER_URL
          ? `${process.env.SERVER_URL}/api/:path*`
          : "http://127.0.0.1:3001/api/:path*",
      },
    ];
  },
};

export default nextConfig;
