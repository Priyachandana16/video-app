/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: 'http://127.0.0.1:5000/api/:path*',
      },
      {
        source: '/assets/:path*',
        destination: 'http://127.0.0.1:5000/assets/:path*',
      },
      {
        source: '/exports/:path*',
        destination: 'http://127.0.0.1:5000/exports/:path*',
      },
      {
        source: '/uploads/:path*',
        destination: 'http://127.0.0.1:5000/uploads/:path*',
      },
    ];
  },
};

module.exports = nextConfig;

