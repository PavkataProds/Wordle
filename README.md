Note: The code is located in "app/Main.hs".

This project enhances the popular game Wordle, where the user guesses a 5-letter word within six attempts. Hints guide the player, with letters colored gray (not in the word), yellow (in the word but incorrect position), and green (correct position).

The improvements include two modes:

1) Game Mode – Features three difficulty levels: Easy, Standard, and Expert.
2) Assistant Mode – Allows the user to provide a secret word for the app to guess.
The project was built using the Cabal system for structuring Haskell packages. To run the game, download the directories and execute the command "cabal run" in the project's subdirectory via the terminal.

Game Mode:
After selecting a difficulty level (e.g., Standard), the user specifies the word length.
The player inputs guesses, and the app provides feedback through wildcards.
In Hard Mode, one hint will be intentionally misleading.
In Easy Mode, additional guidance is available (e.g., confirming if the word is valid or avoiding reused letters). Errors do not reduce the number of attempts.

Assistant Mode:
The user chooses a secret word (e.g., "house"), and the app guesses it.
The app refines its guesses based on previous feedback, ensuring valid Latin alphabet characters ('g', 'y', 'o') are used.
Enjoy the game!
