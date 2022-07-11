const commissioner = "0x44579397d2866716aB34B1e2f77fce964c8616C5"; // MRZ Rinkeby account
const initialAsker = "0x44579397d2866716aB34B1e2f77fce964c8616C5";
const clueInterval = 10 * 60; // New clue every 10 minutes
const expirationIntervalAfterFinalClue = 10 * 60; // Question expires 10 minutes after final clue
const nextAskerTimeoutInterval = 10 * 60; // Next asker has 10 minutes to ask next question

export default [
  commissioner,
  initialAsker,
  clueInterval,
  expirationIntervalAfterFinalClue,
  nextAskerTimeoutInterval,
] as const;
