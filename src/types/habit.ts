export interface Habit {
  id: string;
  name: string;
  icon: string;
  color: string;
  schedule: number[]; // 반복 요일 (0=일, 1=월, ..., 6=토)
  targetTime: string | null; // "HH:mm" 또는 null
  createdAt: Date;
  isArchived: boolean;
}

export interface HabitLog {
  date: string; // "yyyy-MM-dd"
  isCompleted: boolean;
  memo: string | null;
  completedAt: Date | null;
}

export type HabitInput = Omit<Habit, 'id' | 'createdAt'>;
