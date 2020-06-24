#!/usr/bin/env ruby

# author fernando.machado

require_relative "minesweeper"
require "test/unit"

class TestMinesweeper < Test::Unit::TestCase

  def setup
  	height = 5
  	width = 5
  	bombs = 5

  	test_board = Array.new(height) { Array.new(width) }
  	test_board[2][0] = :bomb
  	test_board[1][1] = :bomb
  	test_board[3][2] = :bomb
  	test_board[4][3] = :bomb
  	test_board[0][4] = :bomb

  	@game = Minesweeper.new(width, height, bombs, test_board)
  end


  def test_play_gameover
  	assert(@game.play(0, 0))
  	assert_equal(false, @game.flag(0, 0))

  	assert(@game.play(1, 1))
  	assert_equal(false, @game.play(1, 1))

  	board_state = @game.board_state(xray: true)

  	assert_equal(false, @game.still_playing?)
  	assert_equal(false, @game.victory?)

  	assert_equal(1, board_state[0][0])
  	assert_equal(:unknown_cell, board_state[1][0])
  	assert_equal(:bomb, board_state[2][0])
  	assert_equal(:unknown_cell, board_state[3][0])
  	assert_equal(:unknown_cell, board_state[4][0])
  end

  def test_play_victory
  	assert(@game.play(0, 0))
  	assert(@game.play(0, 1))
  	assert(@game.play(0, 3))
  	assert(@game.play(0, 4))

  	assert(@game.play(1, 0))
  	assert(@game.play(1, 2))
  	assert_equal(false, @game.play(1, 3))
  	assert_equal(false, @game.play(1, 4))

  	assert(@game.play(2, 0))
  	assert(@game.play(2, 1))
  	assert(@game.play(2, 2))
  	assert(@game.play(2, 4))

  	assert(@game.play(3, 0))
  	assert(@game.play(3, 1))
  	assert(@game.play(3, 2))
  	assert(@game.play(3, 3))

  	assert(@game.play(4, 1))
  	assert(@game.play(4, 2))
  	assert_equal(false, @game.play(4, 3))
  	assert(@game.play(4, 4))

  	board_state = @game.board_state(xray: true)
  	print_format = {clear_cell: '_', unknown_cell: '?'}

  	assert_equal(false, @game.still_playing?)
  	assert(@game.victory?)

  	assert_equal(1, board_state[0][0])
  	assert_equal(2, board_state[1][0])
  	assert_equal(1, board_state[3][0])
  	assert_equal(:clear_cell, board_state[4][0])
  end

  def test_flag
  	assert(@game.flag(0, 2))
  	assert_equal(:flag, @game.board_state[2][0])
  end


  def test_unflag
  	assert(@game.flag(0, 2))
  	assert_equal(:flag, @game.board_state[2][0])

  	assert(@game.flag(0, 2))
  	assert_equal(:unknown_cell, @game.board_state[2][0])
  end


  def test_save_load
  	@game.play(0, 0)
  	@game.play(0, 1)
  	board_state_original = @game.board_state
  	@game.save_game()

  	@game = Minesweeper.new()
  	@game = Minesweeper.load_game()

  	assert_equal(board_state_original, @game.board_state)
  	assert(@game.still_playing?)
  end

  def test_save_load_gameover
  	@game.play(0, 0)
  	@game.play(0, 1)
  	@game.play(0, 2)
  	board_state_original = @game.board_state
  	@game.save_game()

  	@game = Minesweeper.new()
  	@game = Minesweeper.load_game()

  	assert_equal(board_state_original, @game.board_state)
  	assert_equal(false, @game.still_playing?)
  	assert_equal(false, @game.victory?)
  end

end
