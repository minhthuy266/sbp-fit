import type { Metadata } from "next";import "./globals.css";
export const metadata: Metadata = {title:"SBP FIT — Stronger Every Day",description:"Fitness challenges for your team"};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
