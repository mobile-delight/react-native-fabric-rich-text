/**
 * @format
 */

import React from 'react';
import ReactTestRenderer from 'react-test-renderer';
import App from '../src/App';

test('should render the RichText Examples title', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer;
  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const root = renderer!.root;
  const titleText = root.findAll(
    node => node.type === 'Text' && node.children.includes('RichText Examples'),
  );
  expect(titleText.length).toBeGreaterThan(0);
});
