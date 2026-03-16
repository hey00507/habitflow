import type { Habit, HabitInput, HabitLog } from '@/types/habit';

/** Firestore 서비스 인터페이스 — Mock 테스트 가능하도록 추상화 */
export interface HabitService {
  // Habit CRUD
  createHabit(input: HabitInput): Promise<Habit>;
  getHabits(): Promise<Habit[]>;
  updateHabit(id: string, input: Partial<HabitInput>): Promise<void>;
  deleteHabit(id: string): Promise<void>;

  // HabitLog
  toggleLog(habitId: string, date: string, memo?: string): Promise<HabitLog | null>;
  getLogs(habitId: string, startDate: string, endDate: string): Promise<HabitLog[]>;
  getAllLogs(startDate: string, endDate: string): Promise<Map<string, HabitLog[]>>;
}
