// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./GuessToken.sol";

contract GuessingGame {
    /// @notice The associated token contract address
    GuessToken public immutable token;

    /// @notice The discrete states of the contract
    enum GameState {
        WaitingForQuestion,
        AnsweringQuestion
    }

    /// @notice The current question and answer
    struct Question {
        /// @notice the address of the user who submitted the question
        address asker;
        /// @notice The question prompt, e.g. "What U.S. president opened trade relations with China?"
        string prompt;
        /// @notice The Keccak-256 hash of the answer.
        /// @dev The contract does not store the answer in plain text because it would be easy to
        /// recover and cheat.
        bytes32 answerHash;
        /// The unix timestamp when the question was submitted
        uint256 timeSubmitted;
        /// @notice An array of up to three clues, e.g. "Made Elvis Presley a federal agent."
        string[3] clues;
        /// @notice The number of clues already submitted.
        /// @dev This field exists for performance reasons so we don't have to iterate `clues`.
        uint8 cluesSubmitted;
    }

    /// @notice An account that has special privileges
    address public commissioner;

    /// @notice The current state of the game
    GameState gameState = GameState.WaitingForQuestion;

    /// @notice The current question, if one is active
    Question public currentQuestion;

    /// @notice The period of time between when clues can be submitted.
    uint256 public clueInterval;

    /// @notice The period of time after the final clue is eligible to be
    /// submitted where the question can be "expired" for a small award.
    uint256 public expirationIntervalAfterFinalClue;

    // MARK: - Next asker info

    /// @notice After answering a question correctly, the answerer has the exclusive privilege of
    /// submitting the next question for a short period of time. If they don't submit a new question
    /// before that time elapses, anyone may submit the next question.
    address public nextAsker;

    /// @notice The timestamp after which anyone can submit the next question, not just the `nextAsker`.
    uint256 public nextAskerTimeoutDate;

    /// @notice The time interval after a question is answered where the answerer has the privilege of
    /// asking the next question.
    uint256 public nextAskerTimeoutInterval;

    // MARK: - Awards

    uint256 public constant submitQuestionAward = 1000 * 10**18;
    uint256 public constant submitClueAward = 100 * 10**18;
    uint256 public constant submitAnswerAward = 10000 * 10**18;
    uint256 public constant expireQuestionAward = 100 * 10**18;

    // MARK: - Events

    /// @notice A new question was submitted
    event SubmitQuestion(address indexed asker, string prompt);
    /// @notice A new clue was submitted by the asker
    event SubmitClue(address indexed asker, string prompt, string clue);
    /// @notice An answer was submitted and accepted for the current question
    event SubmitAnswer(address indexed answerer, address indexed asker, string answer, string prompt);
    /// @notice The question was expired
    event ExpireQuestion(address indexed expirer, address indexed asker, string prompt);

    /// @param _commissioner The address of the game commissioner who has special privileges
    /// @param _initialAsker The address of the initial asker
    /// @param _clueInterval The initial clue interval, i.e. the period of time between when
    /// clues can be submitted.
    /// @param _expirationIntervalAfterFinalClue The period of time after the final clue is
    /// eligible to be submitted where the question can be "expired" for a small award.
    /// @param _nextAskerTimeoutInterval The time interval after a question is answered where
    /// the answerer has the privilege of asking the next question.
    constructor(
        address _commissioner,
        address _initialAsker,
        uint256 _clueInterval,
        uint256 _expirationIntervalAfterFinalClue,
        uint256 _nextAskerTimeoutInterval
    ) {
        token = new GuessToken(this);
        commissioner = _commissioner;
        clueInterval = _clueInterval;
        nextAsker = _initialAsker;
        expirationIntervalAfterFinalClue = _expirationIntervalAfterFinalClue;
        nextAskerTimeoutInterval = _nextAskerTimeoutInterval;
    }

    // MARK: - General/guessing functions

    /// @notice Helper function for checking whether the current question is active.
    function isCurrentQuestionActive() public view returns (bool) {
        return gameState == GameState.AnsweringQuestion;
    }

    /// @notice Returns true if the current question has expired without receiving
    /// an answer. If so, anyone may call `expireQuestion` to receive a small award
    /// and become the next asker.
    function isCurrentQuestionExpired() public view returns (bool) {
        if (isCurrentQuestionActive() == false) {
            // If there is no current active question, this function returns false.
            return false;
        }
        uint256 expiration = currentQuestion.timeSubmitted + (clueInterval * 3) + expirationIntervalAfterFinalClue;
        return block.timestamp >= expiration;
    }

    /// @notice Returns the current question's asker
    function currentQuestionAsker() public view returns (address) {
        return currentQuestion.asker;
    }

    /// @notice Returns the prompt for the current question
    function currentQuestionPrompt() public view returns (string memory) {
        return currentQuestion.prompt;
    }

    /// @notice Returns the clue for the provide index, if it exists
    function getClue(uint8 index) public view returns (string memory) {
        return currentQuestion.clues[index];
    }

    /// @notice Checks whether the provided answer is correct
    function checkAnswer(string calldata _answer) public view returns (bool) {
        require(isCurrentQuestionActive(), "No current question active");
        bytes32 hashedGuess = keccak256(abi.encodePacked(_answer));
        return currentQuestion.answerHash == hashedGuess;
    }

    /// @notice Submit the answer to the question and receive the prize.
    /// @dev You should not call this function with an incorrect answer. Doing so will cause
    /// the function to revert and you will lose gas. You can check if an answer is correct
    /// by calling `checkAnswer`.
    function submitAnswer(string calldata _answer) external anyoneButAsker {
        require(checkAnswer(_answer), "The answer is incorrect");

        nextAsker = msg.sender;
        nextAskerTimeoutDate = block.timestamp + nextAskerTimeoutInterval;
        gameState = GameState.WaitingForQuestion;
        token.mint(msg.sender, submitAnswerAward);

        emit SubmitAnswer(msg.sender, currentQuestion.asker, _answer, currentQuestion.prompt);
        delete currentQuestion;
    }

    /// @notice Expire the question if it is eligible, and queue up next asker
    function expireQuestion() external anyoneButAsker {
        require(isCurrentQuestionExpired(), "The question is not expired");

        nextAsker = msg.sender;
        nextAskerTimeoutDate = block.timestamp + nextAskerTimeoutInterval;
        gameState = GameState.WaitingForQuestion;
        token.mint(msg.sender, expireQuestionAward);

        emit ExpireQuestion(msg.sender, currentQuestion.asker, currentQuestion.prompt);
        delete currentQuestion;
    }

    // MARK: - Asker functions

    /// @notice Submit the next question
    /// @dev Usually, the `nextAsker` will submit the next question, but if the `nextAskerTimeoutDate`
    /// has passed without them submitting, anyone may submit a question.
    function submitQuestion(string calldata _prompt, bytes32 _answerHash) external onlyEligibleSubmitter {
        require(gameState == GameState.WaitingForQuestion, "Can only call when waiting for question");

        currentQuestion.asker = msg.sender;
        currentQuestion.prompt = _prompt;
        currentQuestion.answerHash = _answerHash;
        currentQuestion.timeSubmitted = block.timestamp;
        gameState = GameState.AnsweringQuestion;

        token.mint(msg.sender, submitQuestionAward);
        emit SubmitQuestion(msg.sender, _prompt);
    }

    /// @notice Returns true if the asker is eligible to submit a new clue
    function canSubmitNewClue() public view returns (bool) {
        uint8 cluesSubmitted = currentQuestion.cluesSubmitted;
        if (isCurrentQuestionActive() == false || cluesSubmitted >= 3) {
            // no active question, or already reached max amout of clues
            return false;
        }

        uint256 timeSinceSubmission = block.timestamp - currentQuestion.timeSubmitted;
        uint8 availableClues = uint8(timeSinceSubmission / clueInterval);
        return availableClues > cluesSubmitted;
    }

    /// @notice Submit a new clue
    function submitClue(string calldata _newClue) external onlyAsker {
        require(canSubmitNewClue(), "No available clues unlocked");
        currentQuestion.clues[currentQuestion.cluesSubmitted] = _newClue;
        currentQuestion.cluesSubmitted += 1;
        token.mint(msg.sender, submitClueAward);
        emit SubmitClue(currentQuestion.asker, currentQuestion.prompt, _newClue);
    }

    // MARK: - Commissioner functions

    function updateClueInterval(uint256 _newInterval) external onlyCommissioner {
        clueInterval = _newInterval;
    }

    function updateExpirationIntervalAfterFinalClue(uint256 _expirationIntervalAfterFinalClue)
        external
        onlyCommissioner
    {
        expirationIntervalAfterFinalClue = _expirationIntervalAfterFinalClue;
    }

    function updateNextAsker(address _nextAsker) external onlyCommissioner {
        require(gameState == GameState.WaitingForQuestion, "Can only update asker if waiting for question");
        nextAsker = _nextAsker;
    }

    function updateNextAskerTimeoutInterval(uint256 _nextAskerTimeoutInterval) external onlyCommissioner {
        nextAskerTimeoutInterval = _nextAskerTimeoutInterval;
    }

    // MARK: - Modifiers

    modifier onlyCommissioner() {
        require(msg.sender == commissioner, "Only the commissioner can call this function");
        _;
    }

    modifier onlyAsker() {
        require(msg.sender == currentQuestion.asker, "Only the asker can call this function");
        _;
    }

    modifier anyoneButAsker() {
        require(msg.sender != currentQuestion.asker, "The asker cannot call this function");
        _;
    }

    /// @notice Only someone who is eligible to submit a question at this time
    modifier onlyEligibleSubmitter() {
        require(msg.sender == nextAsker || block.timestamp >= nextAskerTimeoutDate, "Not eligible to submit question");
        _;
    }
}
