/** @type {import('next').NextConfig} */
const backendUrl = process.env.BACKEND_URL || process.env.NEXT_PUBLIC_BACKEND_URL || '';

const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    if (!backendUrl) return [];
    return [
      {
        source: '/api/render/:path*',
        destination: `${backendUrl}/api/render/:path*`,
      },
      {
        source: '/assets/:path*',
        destination: `${backendUrl}/assets/:path*`,
      },
      {
        source: '/exports/:path*',
        destination: `${backendUrl}/exports/:path*`,
      },
      {
        source: '/uploads/:path*',
        destination: `${backendUrl}/uploads/:path*`,
      },
    ];
  },
};

module.exports = nextConfig;

