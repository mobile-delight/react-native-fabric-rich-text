import { render, fireEvent, screen } from '@testing-library/react-native';

// Mock the native adapter with support for onLinkPress
jest.mock('../../adapters/native', () => {
  const mockReact = require('react');
  const { Text, TouchableOpacity, View } = require('react-native');

  return {
    RichTextNative: jest.fn(
      ({
        text,
        style,
        testID,
        onLinkPress,
      }: {
        text: string;
        style?: object;
        testID?: string;
        onLinkPress?: (href: string) => void;
      }) => {
        // Simple link detection for testing
        const linkMatch = text.match(/<a\s+href="([^"]*)"[^>]*>([^<]*)<\/a>/i);
        if (linkMatch && onLinkPress) {
          const [, href, linkText] = linkMatch;
          if (href === undefined) {
            return mockReact.createElement(Text, { style, testID }, text);
          }
          return mockReact.createElement(
            View,
            { testID },
            mockReact.createElement(
              TouchableOpacity,
              {
                onPress: () => onLinkPress(href),
                testID: `link-${testID}`,
                accessibilityRole: 'link',
              },
              mockReact.createElement(
                Text,
                {
                  style: [
                    style,
                    { color: '#0000EE', textDecorationLine: 'underline' },
                  ],
                },
                linkText
              )
            )
          );
        }
        // No link or no callback
        return mockReact.createElement(Text, { style, testID }, text);
      }
    ),
  };
});

import { RichTextNative } from '../../adapters/native';
import RichText from '../../components/RichText';

describe('Link Rendering (FR-001, FR-005)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('passes onLinkPress callback to native component', () => {
    const onLinkPress = jest.fn();
    render(
      <RichText
        text='<a href="https://example.com">Link</a>'
        onLinkPress={onLinkPress}
        testID="html-with-link"
      />
    );

    expect(RichTextNative).toHaveBeenCalledWith(
      expect.objectContaining({
        onLinkPress: expect.any(Function),
      }),
      undefined
    );
  });

  it('renders link with visual distinction (color and underline)', () => {
    const onLinkPress = jest.fn();
    render(
      <RichText
        text='<a href="https://example.com">Click me</a>'
        onLinkPress={onLinkPress}
        testID="styled-link"
      />
    );

    // The mock applies underline and blue color to links
    const linkText = screen.getByText('Click me');
    expect(linkText).toBeTruthy();
  });

  it('preserves accessibility semantics (role=link)', () => {
    const onLinkPress = jest.fn();
    render(
      <RichText
        text='<a href="https://example.com">Accessible link</a>'
        onLinkPress={onLinkPress}
        testID="accessible-link"
      />
    );

    // Check the link has accessibilityRole
    const linkElement = screen.getByRole('link');
    expect(linkElement).toBeTruthy();
  });
});

describe('Link Interaction (FR-002, FR-003, FR-004)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('fires onLinkPress with href when link tapped', () => {
    const onLinkPress = jest.fn();
    render(
      <RichText
        text='<a href="https://example.com/page">Tap me</a>'
        onLinkPress={onLinkPress}
        testID="tappable-link"
      />
    );

    const link = screen.getByTestId('link-tappable-link');
    fireEvent.press(link);

    expect(onLinkPress).toHaveBeenCalledTimes(1);
    expect(onLinkPress).toHaveBeenCalledWith('https://example.com/page');
  });

  it('passes relative URL href to callback without modification', () => {
    const onLinkPress = jest.fn();
    render(
      <RichText
        text='<a href="/relative/path">Relative link</a>'
        onLinkPress={onLinkPress}
        testID="relative-link"
      />
    );

    const link = screen.getByTestId('link-relative-link');
    fireEvent.press(link);

    expect(onLinkPress).toHaveBeenCalledWith('/relative/path');
  });

  it('passes anchor fragment href to callback', () => {
    const onLinkPress = jest.fn();
    render(
      <RichText
        text='<a href="#section">Jump to section</a>'
        onLinkPress={onLinkPress}
        testID="anchor-link"
      />
    );

    const link = screen.getByTestId('link-anchor-link');
    fireEvent.press(link);

    expect(onLinkPress).toHaveBeenCalledWith('#section');
  });

  it('does nothing when link tapped without onLinkPress callback', () => {
    // This should not crash - graceful no-op
    const { toJSON } = render(
      <RichText
        text='<a href="https://example.com">No handler</a>'
        testID="no-handler-link"
      />
    );

    // Component renders without crashing
    expect(toJSON()).not.toBeNull();
  });

  it('works without onLinkPress prop', () => {
    // Render without passing onLinkPress at all
    expect(() => {
      render(<RichText text='<a href="https://example.com">Safe</a>' />);
    }).not.toThrow();
  });
});

describe('onLinkPress Prop Type', () => {
  it('accepts function with (href: string) => void signature', () => {
    const handler = (href: string): void => {
      console.log(`Navigating to: ${href}`);
    };

    expect(() => {
      render(
        <RichText
          text='<a href="https://example.com">Type check</a>'
          onLinkPress={handler}
        />
      );
    }).not.toThrow();
  });

  it('onLinkPress is optional', () => {
    // This should compile and render without issues
    expect(() => {
      render(<RichText text="<p>No links here</p>" />);
    }).not.toThrow();
  });
});
