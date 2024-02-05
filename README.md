Note: Code is located in "app\Main.hs"

The project is an improvement of the famous game "Wordle", in which the user has to guess a 5-letter word, having only 6 given attempts, but also hints related to the choice of letters - coloring in gray if the letter is not present in the answer, in yellow if it's in the word but not in the right place and green if it's in the right position.
The improvements consist in the fact that the project supports two modes - "Game" and "Assistant" and different difficulties of - easy, standard and expert.
The project was built using the "Cabal" system, which provides easier structuring of packages in libraries and programs written in the "Haskell" language. To run the game, the user must download the directories as provided and type the command “cabal run” on the terminal in the project subdirectory.

By selecting Game mode and then on one of three difficulties (eg standard) the game starts and the user is required to enter a word length.

The player enters a new word each time and the app returns the corresponding wildcards.

In hard mode, the game adds one lie to the jokers, and in easy mode, there are additional hints (whether the word is in the dictionary, whether the word has no already used letters, etc.), and in case of a user error, the number of attempts remains the same.

When selecting "Assistant" mode, the user is the one who comes up with a secret word and the app has to guess it. For example, with the player's guessed word "house", the app only suggests words by changing its choice against previously entered data and knows the word accordingly (the user input is required to be n-letter words composed of the Latin letters 'g', 'y' , 'o'):

Enjoy the game!
