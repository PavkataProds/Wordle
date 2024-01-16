module Main where
import System.IO
import System.Win32.Console (setConsoleOutputCP)
import System.Random
import Data.Char (isNumber)
import Text.Read (Lexeme(Number))
import Data.Bits (FiniteBits(finiteBitSize))
import GHC.Read (choose)

main :: IO ()
main = do
  --needed commands to print emoji chars on Windows
  setConsoleOutputCP 65001
  hSetEncoding stdout utf8

  let attemptsCount = 6

  putStrLn "Select mode ('game', 'helper'): "
  input <- getLine
  case input of
    "game" -> do
      putStrLn "Select difficulty ('easy', 'standart', 'hard'): "
      difficulty <- getLine
      case difficulty of
        [] -> return ()
        "easy" -> do
          putStrLn "Enter word length: "
          lengthOfWordStr <- getLine
          putStrLn "Generating word... "
          let lengthOfWord = read lengthOfWordStr
          word <- generateRandomWord lengthOfWord

          easyMode word attemptsCount lengthOfWord [] []
        "standart" -> do
          putStrLn "Enter word length: "
          lengthOfWordStr <- getLine
          putStrLn "Generating word... "
          let lengthOfWord = read lengthOfWordStr
          word <- generateRandomWord lengthOfWord

          standartMode word attemptsCount lengthOfWord
        "hard" -> do
          putStrLn "Enter word length: "
          lengthOfWordStr <- getLine
          putStrLn "Generating word... "
          let lengthOfWord = read lengthOfWordStr
          word <- generateRandomWord lengthOfWord

          attemptsLieIndex <- getStdRandom (randomR (0, attemptsCount))
          positionOfLieInWord <- getStdRandom (randomR (0, lengthOfWord))

          hardMode word attemptsCount lengthOfWord attemptsLieIndex positionOfLieInWord
    "helper" -> do
      putStrLn "Enter word length: "
      lengthOfWordStr <- getLine
      let lengthOfWord = read lengthOfWordStr

      file <- readFile "dictionary.txt"
      let dictionaryNotFiltered = lines file
      let dictionary = filter (\x -> length x == lengthOfWord) dictionaryNotFiltered

      helperMode dictionary "" "" (unknownWord lengthOfWord) lengthOfWord

generateRandomWord :: Int -> IO String
generateRandomWord lengthOfWord = do
  file <- readFile "dictionary.txt"
  let dictionary = lines file
  let filtered = filter (\x -> length x == lengthOfWord) dictionary
  i <- getStdRandom (randomR (0, length filtered - 1))
  let currentLength = length $ filtered !! i
  return $ filtered !! i

data Color
  = Green
  | Yellow
  | Gray
  deriving (Enum, Eq, Show)

toEmoji :: Color -> Char
toEmoji a = case a of
  Green -> '🟩'
  Yellow -> '🟨'
  Gray -> '⬜'
  -- Green -> 'g'
  -- Yellow -> 'y'
  -- Gray -> 'o'

containsLetter :: String -> Char -> Bool
containsLetter [] _ = False
containsLetter (x:xs) y = y == x || containsLetter xs y

colorConnection :: String -> String -> String -> [Color]
colorConnection [] _ _ = []
colorConnection _ [] _ = []
colorConnection guess@(x:xs) comparable@(y:ys) word
  | x == y = Green : colorConnection xs ys word
  | containsLetter word y = Yellow : colorConnection xs ys word
  | otherwise = Gray : colorConnection xs ys word

gameWon :: [Color] -> Bool
gameWon = foldr (\ x -> (&&) (x == Green)) True

-----------------------------------------------------------------_GAME_MODES_-----------------------------------------------------------------

standartMode :: String -> Int -> Int -> IO ()
standartMode [] _ _ = do
  putStrLn "Invalid word"

standartMode word 0 _ = do
  putStrLn $ "Game over! The word was " ++ word

standartMode word n lengthOfWord = do
  putStrLn $ "Enter guess (Attempts left: " ++ show n ++ "): "
  guess <- getLine

  file <- readFile "dictionary.txt"
  let dictionaryNotFiltered = lines file
  let dictionary = filter (\x -> length x == lengthOfWord) dictionaryNotFiltered

  if length guess /= lengthOfWord
    then do
      putStrLn $ "Enter " ++ show lengthOfWord ++ " characters!"
      standartMode word n lengthOfWord
  else do
    let answer = colorConnection word guess word
    putStrLn $ map toEmoji answer

    if gameWon answer then putStrLn "You win!"
    else standartMode word (n - 1) lengthOfWord

easyMode :: String -> Int -> Int -> [Char] -> [Int] -> IO ()
easyMode [] _ _ _ _ = do
  putStrLn "Invalid word"

easyMode word 0 _ _ _ = do
  putStrLn $ "Game over! The word was " ++ word

easyMode word n lengthOfWord usedLetters fixedLetters = do
  if usedLetters /= []
    then do
      putStrLn "Currently used letters: "
      printLetters usedLetters
      putStrLn ""
      let letters = lettersInTheWord word usedLetters
      if letters /= []
        then do
          putStrLn "Currently guessed letters: "
          printLetters letters
          putStrLn ""
          if fixedLetters /= []
            then do
              putStrLn "Currently fixed letters: "
              printFixedLetters word 1 fixedLetters
          else putStrLn "No fixed letters yet"
      else putStrLn "No guessed letters yet"
  else putStrLn "No used letters yet"

  putStrLn $ "Enter guess (Attempts left: " ++ show n ++ "): "
  guess <- getLine

  file <- readFile "dictionary.txt"
  let dictionaryNotFiltered = lines file
  let dictionary = filter (\x -> length x == lengthOfWord) dictionaryNotFiltered

  if length guess /= lengthOfWord
    then do
      putStrLn $ "Enter " ++ show lengthOfWord ++ " characters!"
      easyMode word n lengthOfWord usedLetters fixedLetters
  else if not (contains guess dictionary)
    then do
      putStrLn "Word not in dictionary"
      easyMode word n lengthOfWord usedLetters fixedLetters
  else if not (lettersInPlace word guess fixedLetters)
    then do
      putStrLn "Not using an already guessed letter. Try again!"
      easyMode word n lengthOfWord usedLetters fixedLetters
  else if lettersCrossedOut guess word usedLetters
    then do
      putStrLn "Using an already crossed out letter. Try again!"
      easyMode word n lengthOfWord usedLetters fixedLetters
  else do
    let answer = colorConnection word guess word
    putStrLn $ map toEmoji answer

    let newFixedLetters = updateFixedLetters fixedLetters 1 answer
    let newUsedLetters = addLetters guess usedLetters

    if gameWon answer then putStrLn "You win!"
    else easyMode word (n - 1) lengthOfWord newUsedLetters newFixedLetters

hardMode :: String -> Int -> Int -> Int -> Int -> IO ()
hardMode [] _ _ _ _ = do
  putStrLn "Invalid word"

hardMode word 0 _ _ _ = do
  putStrLn $ "Game over! The word was " ++ word

hardMode word n lengthOfWord attemptsLieIndex positionOfLieInWord = do
  putStrLn $ "Enter guess (Attempts left: " ++ show n ++ "): "
  guess <- getLine

  file <- readFile "dictionary.txt"
  let dictionaryNotFiltered = lines file
  let dictionary = filter (\x -> length x == lengthOfWord) dictionaryNotFiltered

  if length guess /= lengthOfWord
    then do
      putStrLn $ "Enter " ++ show lengthOfWord ++ " characters!"
      hardMode word n lengthOfWord attemptsLieIndex positionOfLieInWord
  else do
    let answer = colorConnection word guess word
    if attemptsLieIndex == n
      then do
        let lie = lieGenerator answer positionOfLieInWord
        putStrLn $ map toEmoji lie
    else putStrLn $ map toEmoji answer

    if gameWon answer then putStrLn "You win!"
    else hardMode word (n - 1) lengthOfWord attemptsLieIndex positionOfLieInWord

----------------------------------------------------------------------------------------------------------------------------------------------

contains :: Eq a => a -> [a] -> Bool
contains elem myList
  = case myList of
      [] -> False
      x : xs | x == elem -> True
      _ : xs -> contains elem xs

addLetters :: String -> [Char] -> [Char]
addLetters [] y = y
addLetters (x:xs) y =
  if contains x y
    then addLetters xs y
  else addLetters xs (x : y)

printLetters :: String -> IO ()
printLetters [] = return ()
printLetters (x:xs) = do
  putChar x
  putChar ' '
  printLetters xs

printFixedLetters :: String -> Int -> [Int] -> IO ()
printFixedLetters [] _ _ = putStrLn ""
printFixedLetters (x:xs) index fixedLetters = 
  if contains index fixedLetters
    then do
      putChar x
      putChar ' '
      printFixedLetters xs (index + 1) fixedLetters
  else printFixedLetters xs (index + 1) fixedLetters

--Fills a Char array containing already used letters
--Use: easy mode
lettersInTheWord :: String -> [Char] -> [Char]
lettersInTheWord _ [] = []
lettersInTheWord word (x:xs) =
  if contains x word
    then x : lettersInTheWord word xs
  else lettersInTheWord word xs

--Returns a Char in range 1 - lengthOfWord
--No corner case checks because it is only used in safe functions (No input)
letterAtIndex :: String -> Int -> Char
letterAtIndex (x:xs) 1 = x
letterAtIndex (x:xs) n = letterAtIndex xs (n - 1)

--Returns whether the input matches all the Green squares
--Use: easy mode
lettersInPlace :: String -> String -> [Int] -> Bool
lettersInPlace _ _ [] = True
lettersInPlace _ [] _ = True
lettersInPlace [] _ _ = True
lettersInPlace word guess (z:zs) =
  letterAtIndex word z == letterAtIndex guess z &&
  lettersInPlace word guess zs

--Adds indexes of new fixed letters
--Use: easy mode
updateFixedLetters :: [Int] -> Int -> [Color] -> [Int]
updateFixedLetters fixedLetters _ [] = fixedLetters
updateFixedLetters fixedLetters n (x:xs) =
  if x == Green && not (contains n fixedLetters)
    then updateFixedLetters (n : fixedLetters) (n + 1) xs
  else updateFixedLetters fixedLetters (n + 1) xs

lettersCrossedOut :: String -> String -> [Char] -> Bool
lettersCrossedOut [] _ _ = False
lettersCrossedOut (x:xs) word usedLetters =
  (not (contains x word) && contains x usedLetters) ||
  lettersCrossedOut xs word usedLetters

--Generates a wrong color in a list of colors - the answer,
--on a specific position (random Int in range 1 - lengthOfWord)
--Use: hard mode
lieGenerator :: [Color] -> Int -> [Color]
lieGenerator [] _ = []
lieGenerator (x:xs) 1
  | x == Green = Gray : xs
  | x == Yellow = Green : xs
  | otherwise = Yellow : xs
lieGenerator (x:xs) n = x : lieGenerator xs (n - 1)

-----------------------------------------------------------------_HELPER_MODE_-----------------------------------------------------------------

helperMode :: [String] -> [Char] -> [Char] -> [Char] -> Int -> IO ()
helperMode dictionary usedLetters guessedLetters fixedLetters lengthOfWord = do

  let newDictionary = generateNewDictionary dictionary usedLetters guessedLetters fixedLetters

  i <- getStdRandom (randomR (0, length newDictionary - 1))
  let guess = newDictionary !! i

  putStrLn $ "My guess is \"" ++ guess ++"\""
  putStrLn "Enter colors (g == Green, y == Yellow, o == Gray): "

  answer <- getLine

  let newUsedLetters = addLetters guess usedLetters
  let newGuessedLetters = evaluateGuessedLetters guess answer guessedLetters
  let newFixedLetters = evaluateFixedLetters guess answer fixedLetters

  if gameWonHelper answer lengthOfWord
    then do
      putStrLn "We won!"
  else do
    helperMode newDictionary newUsedLetters newGuessedLetters newFixedLetters lengthOfWord

-----------------------------------------------------------------------------------------------------------------------------------------------

generateNewDictionary :: [String] -> [Char] -> [Char] -> [Char] -> [String]
generateNewDictionary [] _ _ _ = []
generateNewDictionary (x:xs) usedLetters guessedLetters fixedLetters =
  if isWordCompatible x usedLetters guessedLetters fixedLetters && 
    allLettersIncluded x guessedLetters
    then x : generateNewDictionary xs usedLetters guessedLetters fixedLetters
  else generateNewDictionary xs usedLetters guessedLetters fixedLetters

isWordCompatible :: String -> [Char] -> [Char] -> [Char] -> Bool
isWordCompatible [] _ _ _ = True
isWordCompatible word@(x:xs) usedLetters guessedLetters fixedLetters@(y:ys) =
  (not (contains x usedLetters) || contains x guessedLetters) &&
  (y == '?' || y == x) &&
  isWordCompatible xs usedLetters guessedLetters ys

allLettersIncluded :: String -> [Char] -> Bool
allLettersIncluded _ [] = True
allLettersIncluded word (x:xs) = contains x word && allLettersIncluded word xs

unknownWord :: Int -> String
unknownWord 1 = "?"
unknownWord n = '?' : unknownWord (n - 1)

--g == Green, y == Yellow, o == Gray
evaluateGuessedLetters :: String -> String -> [Char] -> [Char]
evaluateGuessedLetters [] _ z = z
evaluateGuessedLetters guess@(x:xs) answer@(y:ys) z =
  if (y == 'g' || y == 'y') && not (contains x z)
    then evaluateGuessedLetters xs ys (x : z)
  else evaluateGuessedLetters xs ys z

evaluateFixedLetters ::  String -> String -> String -> [Char]
evaluateFixedLetters [] _ z = z
evaluateFixedLetters guess@(x:xs) answer@(y:ys) fixedLetters@(z:zs) =
  if y == 'g'
    then x : evaluateFixedLetters xs ys zs
  else '?' : evaluateFixedLetters xs ys zs

gameWonHelper :: [Char] -> Int -> Bool
gameWonHelper _ 0 = True
gameWonHelper (x:xs) n = (x == 'g') && gameWonHelper xs (n - 1)