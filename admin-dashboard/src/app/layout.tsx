import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'My Invitation | Video Template Admin Studio',
  description: 'Visual Timeline Editor & Dynamic Video Invitation Rendering Engine Dashboard',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-[#0A0A0F] text-slate-100 min-h-screen antialiased">
        {children}
      </body>
    </html>
  );
}

