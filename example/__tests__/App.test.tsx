/**
 * @format
 */

import React from 'react';
import { render } from '@testing-library/react-native';
import App from '../src/App';

test('renders App successfully', () => {
  const { toJSON } = render(<App />);
  expect(toJSON()).toBeTruthy();
});
