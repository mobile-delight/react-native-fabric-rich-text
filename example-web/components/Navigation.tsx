'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const navItems = [
  { href: '/', label: 'Home' },
  { href: '/basic', label: 'Basic' },
  { href: '/truncation', label: 'Truncation' },
  { href: '/styling', label: 'Styling' },
  { href: '/rtl', label: 'RTL' },
];

export default function Navigation() {
  const pathname = usePathname();

  return (
    <nav className="bg-gray-100 dark:bg-gray-900 border-b border-gray-200 dark:border-gray-800">
      <div className="max-w-4xl mx-auto px-4">
        <div className="flex items-center justify-between h-14">
          <Link
            href="/"
            className="font-semibold text-lg text-gray-900 dark:text-gray-100"
          >
            FabricRichText
          </Link>
          <ul className="flex gap-6">
            {navItems.map((item) => {
              const isActive = pathname === item.href;
              return (
                <li key={item.href}>
                  <Link
                    href={item.href}
                    className={`text-sm transition-colors ${
                      isActive
                        ? 'text-blue-600 dark:text-blue-400 font-medium'
                        : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'
                    }`}
                  >
                    {item.label}
                  </Link>
                </li>
              );
            })}
          </ul>
        </div>
      </div>
    </nav>
  );
}
