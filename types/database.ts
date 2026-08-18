export type ProfileStats = {
  xp: number;
  streak: number;
  longest: number;
  answered: number;
  correct: number;
  done: string | null;
};

export type ProfileRow = {
  username: string;
  display_name: string;
  total_xp: number;
  current_streak: number;
  longest_streak: number;
  total_answered: number;
  total_correct: number;
  last_daily_completed_on: string | null;
};

export function toProfileStats(profile: ProfileRow): ProfileStats {
  return {
    xp: profile.total_xp,
    streak: profile.current_streak,
    longest: profile.longest_streak,
    answered: profile.total_answered,
    correct: profile.total_correct,
    done: profile.last_daily_completed_on,
  };
}
