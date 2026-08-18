export type QuizQuestion = {
  id: string;
  category: string;
  topic: string;
  prompt: string;
  answer: string;
  aliases: string[];
  explanation: string;
};

export const questions: QuizQuestion[] = [
  { id: "q1", category: "History", topic: "U.S. History", prompt: "This document begins with 'We the People' and established the framework of the United States federal government. Name it.", answer: "U.S. Constitution", aliases: ["constitution", "the constitution", "united states constitution"], explanation: "Drafted in 1787, the Constitution replaced the Articles of Confederation as the nation's governing framework." },
  { id: "q2", category: "Science", topic: "Chemistry", prompt: "What element has atomic number 8 and is essential for aerobic respiration?", answer: "Oxygen", aliases: ["oxygen", "o"], explanation: "Oxygen has eight protons. Molecular oxygen is used during cellular respiration." },
  { id: "q3", category: "Literature", topic: "British Literature", prompt: "This George Orwell novel follows Winston Smith as he resists the surveillance state of Oceania. Name it.", answer: "1984", aliases: ["1984", "nineteen eighty four"], explanation: "Published in 1949, 1984 introduced terms such as Big Brother, doublethink, and thoughtcrime." },
  { id: "q4", category: "Fine Arts", topic: "Painting", prompt: "Which Dutch artist painted The Starry Night while staying at an asylum in Saint-Remy?", answer: "Vincent van Gogh", aliases: ["van gogh", "vincent van gogh"], explanation: "Van Gogh painted The Starry Night in 1889, drawing on the view from Saint-Paul-de-Mausole." },
  { id: "q5", category: "Geography", topic: "Capitals", prompt: "What is the capital city of Australia?", answer: "Canberra", aliases: ["canberra"], explanation: "Canberra was selected as a compromise between Sydney and Melbourne and became the national capital in 1913." },
  { id: "q6", category: "Civics", topic: "Supreme Court", prompt: "Which 1803 Supreme Court case established the principle of judicial review?", answer: "Marbury v. Madison", aliases: ["marbury v madison", "marbury versus madison", "marbury"], explanation: "The decision established the Supreme Court's power to invalidate unconstitutional laws." },
  { id: "q7", category: "Mythology", topic: "Greek", prompt: "In Greek mythology, who is the god of the sea and brother of Zeus?", answer: "Poseidon", aliases: ["poseidon"], explanation: "Poseidon, one of the three sons of Cronus, rules the sea and carries a trident." },
  { id: "q8", category: "Math", topic: "Geometry", prompt: "What theorem states that the square of a right triangle's hypotenuse equals the sum of the squares of its other two sides?", answer: "Pythagorean theorem", aliases: ["pythagorean theorem", "pythagoras theorem"], explanation: "The Pythagorean theorem is written a^2 + b^2 = c^2, where c is the hypotenuse." },
  { id: "q9", category: "Science", topic: "Biology", prompt: "What organelle is known as the powerhouse of the cell because it generates most cellular ATP?", answer: "Mitochondrion", aliases: ["mitochondria", "mitochondrion"], explanation: "Mitochondria use oxidative phosphorylation to produce ATP, the cell's main energy currency." },
  { id: "q10", category: "History", topic: "World History", prompt: "Which empire captured Constantinople in 1453 under Sultan Mehmed II?", answer: "Ottoman Empire", aliases: ["ottomans", "ottoman empire"], explanation: "The conquest ended the Byzantine Empire and made Constantinople an Ottoman capital." },
];

export function normalizeAnswer(value: string) {
  return value.toLowerCase().replace(/[^a-z0-9 ]/g, "").replace(/\s+/g, " ").trim();
}

export function isCorrectAnswer(question: QuizQuestion, submitted: string) {
  const normalized = normalizeAnswer(submitted);
  return [question.answer, ...question.aliases].some(
    (accepted) => normalizeAnswer(accepted) === normalized,
  );
}
