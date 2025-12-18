import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Staff4dshire Properties',
  description: 'Staff and Subcontractor Management System',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}

