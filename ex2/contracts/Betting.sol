pragma solidity ^0.4.15;

contract Betting {
	/* Standard state variables */
	address public owner;
	address public gamblerA;
	address public gamblerB;
	address public oracle;
	uint[] outcomes;	// Feel free to replace with a mapping

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
		uint outcome;
		uint amount;
		bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet) bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetMade(address gambler);
	event BetClosed();

	/* Uh Oh, what are these? */
	modifier OwnerOnly() {
		if (msg.sender == owner) {_;}
	}
	modifier OracleOnly() {
		if (msg.sender == oracle) {_;}
	}

	/* Constructor function, where owner and outcomes are set */
	function Betting(uint[] _outcomes) {
		owner = msg.sender;
		outcomes = _outcomes;
	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
		if (msg.sender == owner) {
			oracle = _oracle;
			return oracle;
		}
	}

	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable returns (bool) {
		require(address(gamblerA) == 0 || address(gamblerB) == 0);

		bets[msg.sender] = Bet({
			outcome: _outcome,
			amount: msg.value,
			initialized: true
		});

		if (address(gamblerA) == 0) {
			gamblerA = msg.sender;
			BetMade(gamblerA);
			return true;
		} else {
			gamblerB = msg.sender;
			BetMade(gamblerB);

			// ensure bets are not the same
			if (bets[gamblerA].outcome == bets[gamblerB].outcome) {
				revert();
				return false;
			}
			return true;
		}
	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
		if (_outcome == bets[gamblerA].outcome) {
			winnings[gamblerA] += (bets[gamblerA].amount + bets[gamblerB].amount);
		} else if (_outcome == bets[gamblerB].outcome) {
			winnings[gamblerB] += (bets[gamblerA].amount + bets[gamblerB].amount);
		} else { // transfer funds to oracle
			winnings[oracle] += (bets[gamblerA].amount + bets[gamblerB].amount);
		}
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
		require(winnings[msg.sender] > 0);

		if (winnings[msg.sender] >= withdrawAmount) {
			if (msg.sender.send(remainingBal)) {
				winnings[msg.sender] -= withdrawAmount;
				return winnings[msg.sender];
			}
		}
	}

	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
		return outcomes;
	}

	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
		return winnings[msg.sender];
	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
		delete(gamblerA);
		delete(gamblerB);
		delete(oracle);
		delete(bets[gamblerA]);
		delete(bets[gamblerB]);
	}

	/* Fallback function */
	function() payable {
		revert();
	}
}
