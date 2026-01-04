'use client';

import { useState, type ReactNode } from 'react';
import CodeBlock from './CodeBlock';

interface DemoSectionProps {
  title: string;
  description?: string;
  code: string;
  children: ReactNode;
}

export default function DemoSection({
  title,
  description,
  code,
  children,
}: DemoSectionProps) {
  const [showCode, setShowCode] = useState(false);

  return (
    <section className="mb-8 border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
      <div className="p-4 bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="font-semibold text-gray-900 dark:text-gray-100">
              {title}
            </h3>
            {description && (
              <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                {description}
              </p>
            )}
          </div>
          <button
            onClick={() => setShowCode(!showCode)}
            className="text-sm px-3 py-1 rounded border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
          >
            {showCode ? 'Hide Code' : 'Show Code'}
          </button>
        </div>
      </div>

      {showCode && <CodeBlock code={code} />}

      <div className="p-4 bg-white dark:bg-gray-900">{children}</div>
    </section>
  );
}
