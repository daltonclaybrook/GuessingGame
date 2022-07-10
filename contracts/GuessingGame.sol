// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./GuessToken.sol";

contract GuessingGame {
    /// @notice The associated token contract address
    GuessToken public immutable token;

    /// @notice The discrete states of the contract
    enum GameState { WaitingForQuestion, Guessing }

    /// @notice The current question and answer
    struct Question {
        /// @notice the address of the user who submitted the question
        address asker;
        /// @notice The question prompt, e.g. "What U.S. president opened trade relations with China?"
        string prompt;
        /// @notice An array of up to three clues, e.g. "Made Elvis Presley a federal agent."
        string[3] clues;
        /// @notice The number of clues already submitted.
        /// @dev This field exists for performance reasons so we don't have to iterate `clues`.
        uint8 cluesSubmitted;
        /// @notice The Keccak-256 hash of the answer.
        /// @dev The contract does not store the answer in plain text because it would be easy to
        /// recover and cheat.
        bytes32 answerHash;
        /// The unix timestamp when the question was submitted
        uint256 timeSubmitted;
    }

    /// @notice An account that has special privileges
    address public commissioner;

    /// @notice The current state of the game
    GameState gameState = GameState.WaitingForQuestion;

    /// @notice The current question, if one is active
    Question public currentQuestion;

    /// @notice The address of the next person to ask a question
    address public nextAsker;

    /// @notice The period of time between when clues can be submitted.
    uint256 public clueInterval;

    // MARK: - Events

    /// @notice A new question was submitted
    event SubmitQuestion(address indexed asker, string prompt);
    /// @notice A new clue was submitted by the asker
    event SubmitClue(address indexed asker, string prompt, string clue);
    /// @notice An answer was submitted and accepted for the current question
    event SubmitAnswer(address indexed answerer, address indexed asker, string answer, string prompt);

    /// @param _commissioner The address of the game commissioner who has special privileges
    /// @param _clueInterval The initial clue interval, i.e. the period of time between when
    /// @param _asker The address of the initial asker
    /// clues can be submitted.
    constructor(address _commissioner, uint256 _clueInterval, address _asker) {
        token = new GuessToken(this);
        commissioner = _commissioner;
        clueInterval = _clueInterval;
        nextAsker = _asker;
    }

    // MARK: - General/guessing functions

    /// @notice Helper function for checking whether the current question is active.
    /// @dev The question is considered active if its `timeSubmitted` property != 0.
    function isCurrentQuestionActive() public view returns (bool) {
        return currentQuestion.timeSubmitted == 0;
    }

    /// @notice Returns the clue for the provide index, if it exists
    function getClue(uint8 index) public view returns (string memory) {
        return currentQuestion.clues[index];
    }

    /// @notice Checks whether the provided answer is correct
    function checkAnswer(string calldata _answer) public view returns (bool) {
        require(isCurrentQuestionActive(), "No current question active");
        bytes32 hashedGuess = keccak256(abi.encode(_answer));
        return currentQuestion.answerHash == hashedGuess;
    }

    /// @notice Submit the answer to the question and receive the prize.
    /// @dev You should not call this function with an incorrect answer. Doing so will cause
    /// the function to revert and you will lose gas. You can check if an answer is correct 
    /// by called `checkAnswer`.
    function submitAnswer(string calldata _answer) external notAsker {
        require(checkAnswer(_answer), "The answer is incorrect");

        nextAsker = msg.sender;
        emit SubmitAnswer(msg.sender, currentQuestion.asker, _answer, currentQuestion.prompt);
        delete currentQuestion;
        // todo: pay winner
    }

    // MARK: - Asker functions

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
        emit SubmitClue(currentQuestion.asker, currentQuestion.prompt, _newClue);
        // todo: pay them for submitting a clue to incentivize it?
    }

    // MARK: - Commissioner functions

    function updateClueInterval(uint256 _newInterval) external onlyCommissioner {
        clueInterval = _newInterval;
    }

    // MARK: - Modifiers

    modifier onlyCommissioner {
        require(msg.sender == commissioner, "Only the commissioner can call this function");
        _;
    }

    modifier onlyAsker {
        require(msg.sender == currentQuestion.asker, "Only the asker can call this function");
        _;
    }

    modifier notAsker {
        require(msg.sender != currentQuestion.asker, "The asker cannot call this function");
        _;
    }
}
