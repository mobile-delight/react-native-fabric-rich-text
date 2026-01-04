import type { TextStyle } from 'react-native';
import type { CSSProperties } from 'react';
import { convertStyle } from '../../../adapters/web/StyleConverter';

describe('StyleConverter Types', () => {
  it('should have ConvertStyleFn type signature', () => {
    type ConvertStyleFn = (style?: TextStyle) => CSSProperties;

    const mockConvert: ConvertStyleFn = (
      _style?: TextStyle
    ): CSSProperties => ({});

    expect(typeof mockConvert).toBe('function');
  });
});

describe('convertStyle', () => {
  it('should convert fontSize number to px string', () => {
    const result = convertStyle({ fontSize: 16 });
    expect(result).toEqual({ fontSize: '16px' });
  });

  it('should passthrough fontWeight', () => {
    const result = convertStyle({ fontWeight: 'bold' });
    expect(result).toEqual({ fontWeight: 'bold' });
  });

  it('should passthrough color', () => {
    const result = convertStyle({ color: '#FF0000' });
    expect(result).toEqual({ color: '#FF0000' });
  });

  it('should convert lineHeight number to px string', () => {
    const result = convertStyle({ lineHeight: 24 });
    expect(result).toEqual({ lineHeight: '24px' });
  });

  it('should return empty object for undefined style', () => {
    const result = convertStyle(undefined);
    expect(result).toEqual({});
  });

  it('should return empty object for empty style object', () => {
    const result = convertStyle({});
    expect(result).toEqual({});
  });

  it('should convert multiple properties correctly', () => {
    const result = convertStyle({
      fontSize: 16,
      fontWeight: 'bold',
      color: '#FF0000',
      lineHeight: 24,
    });
    expect(result).toEqual({
      fontSize: '16px',
      fontWeight: 'bold',
      color: '#FF0000',
      lineHeight: '24px',
    });
  });
});
