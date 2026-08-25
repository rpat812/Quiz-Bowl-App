export type QuestionDifficulty = "easy" | "medium" | "hard";

export type QuestionType =
  | "multiple_choice"
  | "fill_in_the_blank"
  | "true_false"
  | "short_answer";

export type PracticeQuestion = {
  id: string;
  category: string;
  subcategory: string;
  difficulty: QuestionDifficulty;
  questionType: QuestionType;
  region: string;
  timePeriod: string;
  tags: string[];
  question: string;
  options: string[];
};

export type AnswerCheck = {
  correct: boolean;
  correctAnswer: string | boolean;
  explanation: string;
};
