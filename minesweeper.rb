#!/usr/bin/env ruby

# author fernando.machado

require 'set'
require 'stringio'


class Minesweeper
  # Construtor de Minesweeper
  def initialize(width = 10, height = 10, mines = 10, mine_board = nil, game_board = nil, mine_hit = false)
    @width = width
    @height = height
    @mines = mines

    # criando board de jogo, inicialmente desconhecido
    if (game_board != nil)
    	@game_board = game_board
    else
    	@game_board = new_board(:unknown_cell)
	end

    # definindo objetivo de células abertas a ser atingido
    @clear_cells_count = 0
    @clear_cells_goal = @width * @height - @mines

    # definindo flag que indica se o usuário já clicou em uma mina
    @mine_hit = mine_hit

    if (mine_board != nil)
    	@mine_board = mine_board
    elsif (width * height <= mines)
      # jogo impossível. criando board de minas completamente preenchido
      @mine_board = new_board(:bomb)
    else
      # jogo possível. criando board de minas, inicialmente vazio
      @mine_board = new_board()

      # determinando posições aleatórias, porém únicas, para distribuição no board de minas
      mines_yx = Set.new()
      while (mines_yx.length < mines)
        x = rand(width)
        y = rand(height)
        if (mines_yx.add?([y, x]) != nil)
          @mine_board[y][x] = :bomb
        end
      end
    end
  end

  # Método usado para retornar a representação atual do jogo, indicando o estado atual de cada célula - se está fechada ou aberta,
  # se possui uma bandeira adicionada ou se representa uma mina revelada.
  # No caso das células abertas, um número inteiro indicando quantas minas estão em sua vizinhança.
  # Adicionalmente, ao passar o hash {xray: true} como parâmetro após o término do jogo, também será revelada a localização de todas as bombas.
  def board_state(custom_options = nil)
    options = {
      xray: false,
    }
    if (custom_options != nil)
      options.merge!(custom_options)
    end

    # definindo board que irá conter o estado atual do jogo
    state_board = new_board()

    # zerado contador de células abertas
    @clear_cells_count = 0

    # percorre todas as posições do board de jogadas para trazer seus valores para o board de estado
    for y in 0..@height-1 do
      for x in 0..@width-1 do
        if (options[:xray] and !still_playing? and has_mine?(x, y))
          # caso a opção xray esteja ativa e o jogo concluído, adiciona também a localização das minas do mine_board
          state_board[y][x] = :bomb
        elsif (@game_board[y][x] == :clear_cell)
          # caso a célula esteja aberta, adiciona a mesma ao contador de células abertas
          @clear_cells_count = @clear_cells_count + 1

          # calculando o número de minas na vizinhança. se não houverem minas, continua usando o rótulo :clear_cell
          neighbour_mines = get_neighbour_mines(x, y)
          state_board[y][x] = neighbour_mines == 0 ? :clear_cell : neighbour_mines
        else
          # em todos os outros casos, apenas replica a informação do board de jogadas
          state_board[y][x] = @game_board[y][x]
        end
      end
    end

    return state_board
  end

  # Método usado para, dada uma coordenada (x, y), realizar a operação de clicar em sua respectiva célula, tornando-a aberta.
  # Caso a célula clicada seja válida, não contenha bandeiras ou minas, a mesma e todas as suas vizinhas que atendam a este requisito serão abertas.
  # Caso a coordenada informada corresponda a localização de uma mina, atualiza o board de jogo com esta informação.
  # Retorna um booleano informando se a jogada foi válida.
  def play(x, y)
    if (!invalid?(x, y) and @game_board[y][x] != :flag and has_mine?(x, y))
		if (@game_board[y][x] == :bomb)
			# se já foi clicada, a jogada não é válida
			return false
		else
			# se a célula é válida e não foi clicada, não foi marcada com bandeira e contém uma mina, é game over.
			@game_board[y][x] = :bomb
			@mine_hit = true
			return true
		end
    end

    # caso contrário, abre a célula (e suas células vizinhas, recursivamente)
    return open_cell(x, y)
  end

  # Método privado usado para abrir uma célula ainda não-clicada e que não contenha bandeira ou mina.
  # Uma vez chamado para uma coordenada (x, y) repete o processo entre seus vizinhos próximos de maneira recursiva.
  def open_cell(x, y)
    if (invalid?(x, y) or @game_board[y][x] == :clear_cell or @game_board[y][x] == :flag or has_mine?(x, y))
      return false
    end

    # marcando célula selecionada como aberta
    @game_board[y][x] = :clear_cell

    # caso esta célula não tenha nenhuma mina como vizinha, repete a operação para suas células vizinhas
    if (get_neighbour_mines(x, y) == 0)
      get_neighbours(x, y).each do |neighbour|
        open_cell(neighbour[0], neighbour[1])
      end
    end

    return true
  end

  # Método usado para adicionar uma bandeira a uma célula ainda não clicada ou remover a bandeira preexistente da mesma.
  # Retorna um booleano informando se a jogada foi válida.
  def flag(x, y)
    if (invalid?(x, y) or @game_board[y][x] == :clear_cell)
      return false
    end

    @game_board[y][x] = @game_board[y][x] == :flag ? :unknown_cell : :flag
    return true
  end

  # Método usado para verificar se o jogo está em andamento.
  # Retorna true, se o jogo ainda está acontendendo.
  # Retorna false, se todas as células sem minas tiverem sido descobertas ou o jogador tiver clicado em uma mina.
  def still_playing?
    return (!@mine_hit and @clear_cells_count != @clear_cells_goal)
  end

  # Método usado para verificar se o jogador venceu o jogo.
  # Retorna true apenas se todas as células sem minas tiverem sido descobertas.
  def victory?
    return (@clear_cells_count == @clear_cells_goal)
  end

  # Método privado usado para validar se as coordenadas informadas correspondem a uma posição válida no board.
  def invalid?(x, y)
    return (x == nil or y == nil or x < 0 or y < 0 or x >= @width or y >= @height)
  end

  # Método privado usado para auxiliar na criação de boards. O parâmetro filling permite que o board seja inicializado com um valor.
  def new_board(filling = nil)
    return Array.new(@height) { Array.new(@width, filling) }
  end

  # Método privado usado para, dado uma coordenada (x, y), retornar as coordenadas de seus oito vizinhos mais próximos - sem verificar validade.
  def get_neighbours(x, y)
    neighbours = Array.new
    neighbours.push([x-1, y-1])
    neighbours.push([x-1, y])
    neighbours.push([x-1, y+1])
    neighbours.push([x, y-1])
    neighbours.push([x, y+1])
    neighbours.push([x+1, y-1])
    neighbours.push([x+1, y])
    neighbours.push([x+1, y+1])
    return neighbours
  end

  # Método privado usado para, dado uma coordenada (x, y), retornar o número de minas contidas nos seus vizinhos mais próximos válidos.
  def get_neighbour_mines(x, y)
    neighbour_mines = 0
    get_neighbours(x, y).each do |neighbour|
      if (!invalid?(neighbour[0], neighbour[1]) and has_mine?(neighbour[0], neighbour[1]))
        neighbour_mines = neighbour_mines + 1
      end
    end
    return neighbour_mines
  end

  # Método privado usado para, dada uma coordenada (x, y), verificar se a mesma representa a localização de uma mina no board.
  def has_mine?(x, y)
    return @mine_board[y][x] == :bomb
  end

  def save_game()
    s = StringIO.new
    s << Marshal.dump([@width, @height, @mines, @mine_hit, @game_board, @mine_board])
    File.open("game.sav", 'w') {
      |file| file.write(s.string)
    }
  end

  def self.load_game()
  	text = File.open("game.sav").read
  	loaded_data = Marshal.load(text)
  	width = loaded_data[0]
  	height = loaded_data[1]
  	mines = loaded_data[2]
  	#clear_cells_goal = @width * @height - @mines
  	mine_hit = loaded_data[3]
  	game_board = loaded_data[4]
  	mine_board = loaded_data[5]
  	return Minesweeper.new(width, height, mines, mine_board, game_board, mine_hit)
  end

  # Definindo acesso privado aos métodos auxiliares
  private :invalid?, :get_neighbours, :get_neighbour_mines, :open_cell, :has_mine?

  # Definindo atributos usados localmente
  game_board = nil
  mine_board = nil
end



class SimplePrinter
  # Dado um board, realiza a inspeção de cada uma de suas linhas e imprime o resultado na tela.
  def print(board)
    board.each do |row|
      p row
    end
  end
end



class PrettyPrinter
  # Construtor de PrettyPrinter. Aceita como parâmetro um hash que descreve a forma como o board deverá ser impresso.
  # Por padrão, os atributos seguem a norma descrita abaixo. É possível substituir um, nenhum ou múltiplos atributos.
  # Atributos com chaves diferentes das descritas abaixo são ignorados.
  # {
  #   unknown_cell: '.',
  #   clear_cell: ' ',
  #   bomb: '#',
  #   flag: 'F'
  # }
  def initialize(board_format = nil)
    @board_format = {
      unknown_cell: '.',
      clear_cell: ' ',
      bomb: '#',
      flag: 'F'
    }
    if (board_format != nil)
      @board_format.merge!(board_format)
    end
  end

  # Dado um board, navega por cada um de seus elementos e os imprime na tela de acordo com o board_format usado no construtor.
  def print(board)
    board.each do |row|
      s = StringIO.new
      row.each do |col|
        if (col.is_a? Numeric)
          s << col
        else
          s << @board_format[col]
        end
        s << ' '
      end
      puts s.string
    end
    puts ''
  end
end



# Mock contendo exemplo de uso
if __FILE__ == $0
  width = 13
  height = 13
  mines = 3

  game = Minesweeper.new(width, height, mines)

  print_format = {clear_cell: '_', unknown_cell: '?'}

  printer = PrettyPrinter.new(print_format)

  puts "Game Start"
  printer.print(game.board_state)

  while game.still_playing?
    valid_move = game.play(rand(width), rand(height))
    valid_flag = game.flag(rand(width), rand(height))
    if (valid_move or valid_flag)
      printer.print(game.board_state)
    end
  end

  puts "Game Over"
  if game.victory?
    puts "You won! Congratulations! :)"
  else
    puts "You lost! Here's where the mines were located:"
    PrettyPrinter.new(print_format).print(game.board_state(xray: true))
  end

end
