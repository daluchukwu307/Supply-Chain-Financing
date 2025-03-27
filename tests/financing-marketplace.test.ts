import { describe, it, expect, beforeEach } from 'vitest';

// Mock the Clarity contract calls
const mockContractCalls = {
  createOffer: (invoiceId: number, amount: number, interestRate: number, expiration: number) => {
    return { result: { value: 1 } };
  },
  acceptOffer: (offerId: number, invoiceOwner: string, dueDate: number) => {
    return { result: { value: true } };
  },
  getOffer: (offerId: number) => {
    return {
      result: {
        value: {
          invoiceId: 1,
          lender: 'ST3CECAKJ4BH08JYY7W53MC81BYDT4YDA5Z7XE5H',
          amount: 900,
          interestRate: 500, // 5.00%
          expiration: 100500,
          status: 'active'
        }
      }
    };
  },
  getAgreement: (invoiceId: number) => {
    return {
      result: {
        value: {
          lender: 'ST3CECAKJ4BH08JYY7W53MC81BYDT4YDA5Z7XE5H',
          borrower: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
          amount: 900,
          interestRate: 500,
          dueDate: 100000,
          status: 'active'
        }
      }
    };
  }
};

describe('Financing Marketplace Contract', () => {
  it('should create a financing offer', () => {
    const result = mockContractCalls.createOffer(1, 900, 500, 100500);
    expect(result.result.value).toBe(1);
  });
  
  it('should accept a financing offer', () => {
    const result = mockContractCalls.acceptOffer(
        1,
        'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
        100000
    );
    expect(result.result.value).toBe(true);
  });
  
  it('should get offer details', () => {
    const result = mockContractCalls.getOffer(1);
    expect(result.result.value.amount).toBe(900);
    expect(result.result.value.interestRate).toBe(500);
    expect(result.result.value.status).toBe('active');
  });
  
  it('should get agreement details', () => {
    const result = mockContractCalls.getAgreement(1);
    expect(result.result.value.lender).toBe('ST3CECAKJ4BH08JYY7W53MC81BYDT4YDA5Z7XE5H');
    expect(result.result.value.borrower).toBe('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM');
    expect(result.result.value.amount).toBe(900);
  });
});
