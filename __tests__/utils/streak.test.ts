import { describe, it, expect } from 'vitest';
import { calcStreak } from '@/utils/streak';

describe('calcStreak', () => {
  it('연속 날짜 → 정확한 카운트', () => {
    const logs = ['2026-03-14', '2026-03-15', '2026-03-16'];
    expect(calcStreak(logs, '2026-03-16')).toBe(3);
  });

  it('중간 빈 날짜 → 최근 연속만 카운트', () => {
    const logs = ['2026-03-12', '2026-03-13', '2026-03-15', '2026-03-16'];
    expect(calcStreak(logs, '2026-03-16')).toBe(2);
  });

  it('오늘 미완료 → 오늘 제외하고 카운트', () => {
    const logs = ['2026-03-14', '2026-03-15'];
    expect(calcStreak(logs, '2026-03-16')).toBe(2);
  });

  it('로그 없음 → 0', () => {
    expect(calcStreak([], '2026-03-16')).toBe(0);
  });

  it('하루만 완료 → 1', () => {
    const logs = ['2026-03-16'];
    expect(calcStreak(logs, '2026-03-16')).toBe(1);
  });

  it('연말→연초 걸치는 연속 기록', () => {
    const logs = ['2025-12-30', '2025-12-31', '2026-01-01', '2026-01-02'];
    expect(calcStreak(logs, '2026-01-02')).toBe(4);
  });
});
