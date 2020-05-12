module GuessFeedback
  # Mixed in to Computer and Mastermind classes

  def correct_digits_and_place(code_copy, guess)
    digit_and_place = 0
    guess.each_with_index do |guess_num, i|
      guess_num = guess_num.to_i
      if guess_num == code_copy[i].to_i
        digit_and_place += 1
        code_copy[i] = 0 # "Cross off" value now that it's accounted for to avoid double counts
      end
    end
    digit_and_place
  end
  
  def correct_digits_only(code_copy, guess)
    digit_only = 0
    guess.each_with_index do |guess_num, i|
      code_copy.each_with_index do |comp_num, j|
        guess_num = guess_num.to_i
        comp_num = comp_num.to_i
        if i != j && guess_num == comp_num
          digit_only += 1
          code_copy[j] = 0 # "Cross off" value now that it's accounted for to avoid double counts
        end
      end
    end
    digit_only
  end
end

class Player
  attr_reader :role, :guess, :code

  public

  def set_role
    puts "Select which role you'd like to play"
    puts "[1] Codebreaker"
    puts "[2] Codemaker"
    response = gets.chomp
    while !["1","2"].include?(response)
      puts "Please enter a valid option"
      response = gets.chomp
    end
    if response == "1"
      @role = "breaker"
    elsif response == "2"
      @role = "maker"
    end
  end

  def play_round
    if @role == "breaker"
      breaker_play_round
    elsif @role == "maker"
      maker_play_round
    end
  end

  def set_code
    print "Enter your code (ex. 1234): "
    @code = gets.chomp.split("")
    while !valid_code?(@code)
      print "Please enter a valid code: "
      @code = gets.chomp.split("")
    end
  end

  private

  def breaker_play_round
    print "Enter your guess (ex. 1234): "
    @guess = gets.chomp.split("")
    while !valid_code?(@guess)
      print "Please enter a valid guess: "
      @guess = gets.chomp.split("")
    end
  end

  def valid_code?(guess)
    guess.length == 4 && guess.all? { |val| val.to_i > 0 && val.to_i < 7 }
  end

  def maker_play_round
    print "Press enter to see the hackers' guess"
    response = ""
    while response != "\n"
        response = gets
    end
    puts ""
  end
end

class Computer
  include GuessFeedback
  attr_reader :code, :guess

  public

  def set_random_code
    @code = [rand(1..6), rand(1..6), rand(1..6), rand(1..6)]
    puts ""
    puts "Computron has set a random 4-digit code."
    puts ""
  end

  def guess_code(last_digit_and_place = nil, last_digit_only = nil)
    # https://puzzling.stackexchange.com/questions/546/clever-ways-to-solve-mastermind from user master Mind
    if (last_digit_and_place == nil && last_digit_only == nil)
      @guess = [1,1,2,2]
      nums = [1,2,3,4,5,6]
      @possible_guesses = nums.repeated_permutation(4).to_a
    else
      @possible_guesses.delete_if do |arr|
        arr_copy = arr.dup
        last_digit_and_place != correct_digits_and_place(arr_copy, @guess) || last_digit_only != correct_digits_only(arr_copy, @guess)
      end
      @guess = @possible_guesses.first
    end
    puts "The hackers guess #{@guess.join("")}"
  end
end

class Mastermind
  include GuessFeedback
  def initialize
    @rounds = 12
    @game_active = true
    @player = Player.new
    @computer = Computer.new
    @last_digit_and_place = nil
    @last_digit_only = nil
  end

  public

  def play
    while @game_active
      start_message
      @player.set_role
      if @player.role == "breaker"
        @player_won = false
        breaker_play_game
      elsif @player.role == "maker"
        @computer_won = false
        maker_play_game
      end
    end
  end

  private
  
  def start_message
    puts ""
    puts "Welcome to Mastermind!"
  end

  def breaker_play_game
    breaker_explanation_message
    @computer.set_random_code
    @rounds.times do |round|   
      breaker_play_round(round)
      if @player_won
        check_play_again
        break
      end
    end
    if !@player_won
      breaker_lose_message
      check_play_again
    end
  end

  def breaker_explanation_message
    puts "You've been given a mission to hack into the mainframe."
    puts "However, to do so you must get past Computron."
    puts "Computron has guessed a random 4-digit code that you have 12 tries to crack."
    puts "Each number in the code is a digit 1 - 6."
    puts "You'll have to guess the correct numbers in the correct order."
    puts "After each guess, you'll find out: "
    puts "  1. How many numbers you guessed are in the code AND in the correct order."
    puts "  2. How many numbers you guessed are in the code, but NOT in the correct place."
    puts "Can you outsmart Computron?"
    puts "Good luck!"
  end

  def breaker_play_round(round)
    puts "Round #{round + 1}. "
    puts ""
    @player.play_round
    code_copy = @computer.code.dup # to "cross off" values without affecting @computer.code
    digit_and_place = correct_digits_and_place(code_copy, @player.guess)
    digit_only = correct_digits_only(code_copy, @player.guess)
    breaker_check_win(digit_only, digit_and_place)
  end

  def breaker_check_win(digit_only, digit_and_place)
    if digit_and_place == 4
      @player_won = true
      breaker_win_message
    else
      puts "Correct numbers in correct order: #{digit_and_place}"
      puts "Correct numbers, not in correct order: #{digit_only}"
    end
    puts ""
  end

  def breaker_win_message
    puts ""
    puts "You're in! You beat Computron."
  end

  def breaker_lose_message
    puts "You failed to outsmart Computron. Better luck next time!"
    puts ""
  end

  def check_play_again
    response = ""
    while !["y","n"].include?(response)
      puts "Play again? (y/n)"
      response = gets.chomp
    end
    if response == "n"
      @game_active = false
    elsif response == "y"
      clear
    end
  end

  def maker_explanation_message
    puts "Evildoers are attempting to hack into our mainframe."
    puts "It's up to you to stop them with an unbreakable four-digit code!"
    puts "It must be made up of 4 numbers where each one is between 1 and 6."
    puts "The hackers will have #{@rounds} tries to crack the code."
    puts ""
  end

  def maker_play_game
    maker_explanation_message
    @player.set_code
    @rounds.times do |round|   
      maker_play_round(round)
      if @computer_won
        check_play_again
        break
      end
    end
    if !@computer_won
      maker_win_message
      check_play_again
    end
  end

  def maker_play_round(round)
    puts "Round #{round + 1}. "
    puts ""

    @player.play_round
    @computer.guess_code(@last_digit_and_place, @last_digit_only)
  
    code_copy = @player.code.dup
    digit_and_place = correct_digits_and_place(code_copy, @computer.guess)
    digit_only = correct_digits_only(code_copy, @computer.guess)
    maker_check_win(digit_only, digit_and_place)
  end

  def maker_check_win(digit_only, digit_and_place)
    if digit_and_place == 4
      @computer_won = true
      maker_lose_message
    else
      @last_digit_and_place = digit_and_place
      @last_digit_only = digit_only
      puts "Correct numbers in correct order: #{digit_and_place}"
      puts "Correct numbers, not in correct order: #{digit_only}"
    end
    puts ""
  end

  def maker_lose_message
    puts "The hackers are in, you've failed!"
    puts ""
  end

  def maker_win_message
    puts "The hackers have been thwarted! You win!!"
    puts ""
  end

  def clear
    @last_digit_and_place = nil
    @last_digit_only = nil
  end
end

game = Mastermind.new
game.play
