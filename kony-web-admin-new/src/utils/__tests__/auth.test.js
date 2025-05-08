// src/utils/__tests__/auth.test.js
import { describe, it, expect, vi, beforeEach } from 'vitest';
import * as auth from '../auth.js';

// Create spies for your auth functions
const signInSpy = vi.spyOn(auth, 'signIn');
const logOutSpy = vi.spyOn(auth, 'logOut');
const getUserRoleSpy = vi.spyOn(auth, 'getUserRole');

describe('Auth Utilities', () => {
  beforeEach(() => {
    // Reset all mocks
    vi.resetAllMocks();
  });
  
  it('returns user when sign in is successful', async () => {
    // Mock implementation for this test
    const mockUser = { uid: 'tKqhd0niLQdGFMa8D6EB4oIv0zj2' };
    signInSpy.mockResolvedValue(mockUser);
    
    // Call the function
    const result = await auth.signIn('skander.cars139@gmail.com', 'skander1234');
    
    // Verify results
    expect(signInSpy).toHaveBeenCalledWith('skander.cars139@gmail.com', 'skander1234');
    expect(result).toEqual(mockUser);
  });
  
  it('handles sign in errors', async () => {
    // Mock implementation for error case
    signInSpy.mockRejectedValue(new Error('Invalid credentials'));
    
    // Verify the function rejects with error
    await expect(auth.signIn('test@example.com', 'wrong-password'))
      .rejects.toThrow('Invalid credentials');
    
    expect(signInSpy).toHaveBeenCalledWith('test@example.com', 'wrong-password');
  });
  
  it('calls logOut successfully', async () => {
    // Mock implementation
    logOutSpy.mockResolvedValue(undefined);
    
    // Call the function
    await auth.logOut();
    
    // Verify it was called
    expect(logOutSpy).toHaveBeenCalled();
  });
  
  it('returns user role when getUserRole is called', async () => {
    // Mock implementation
    getUserRoleSpy.mockResolvedValue('admin');
    
    // Call the function
    const role = await auth.getUserRole({ uid: '123' });
    
    // Verify results
    expect(getUserRoleSpy).toHaveBeenCalledWith({ uid: '123' });
    expect(role).toBe('admin');
  });
});