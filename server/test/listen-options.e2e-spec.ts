import { resolveListenHost } from '../src/listen-options';

describe('Server listen options', () => {
  it('listens on all interfaces by default for local device testing', () => {
    expect(resolveListenHost({})).toBe('0.0.0.0');
  });

  it('allows the listen host to be overridden', () => {
    expect(resolveListenHost({ HOST: '127.0.0.1' })).toBe('127.0.0.1');
  });
});
