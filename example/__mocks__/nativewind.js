// Mock nativewind for Jest - cssInterop is a no-op in tests
module.exports = {
  cssInterop: jest.fn(() => {}),
};
