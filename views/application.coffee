Blackjack = {}

# -----------------------------------------------------------------------------
# Events
# -----------------------------------------------------------------------------
Blackjack.Events = _.extend({}, Backbone.Events)


# -----------------------------------------------------------------------------
# Models
# -----------------------------------------------------------------------------
Blackjack.Card = Backbone.Model.extend
  defaults: { visible: true }

  entityForSuit: ->
    "&#{@get('suit')};"

  isAce: ->
    @get('name') == 'A'

  value: ->
    switch @get('name')
      when 'A' then 11 # assume 11 but could be 1 depending on hand
      when 'J', 'Q', 'K' then 10
      else parseInt(@get('name'))

Blackjack.Deck = Backbone.Collection.extend
  model: Blackjack.Card

  initialize: ->
    suits = ['hearts', 'clubs', 'spades', 'diams']
    names = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    for suit in suits
      for name in names
        @add(suit: suit, name: name)
    @models = @shuffle()

  deal: (count = 1) ->
    cards = @take(count)
    @remove(cards)
    cards

Blackjack.Hand = Backbone.Collection.extend
  model: Blackjack.Card

  cards: (index) ->
    if index then @models[index-1] else @models

  hit: ->
    @add(Blackjack.Session.currentGame.deck.deal(1))

  aces: ->
    @cards().filter (card) -> card.isAce()

  value: ->
    values = @cards().map (card) -> card.value()
    totalWithAcesAsEleven = _.reduce(values, ((memo, num) -> memo + num), 0)
    _.reduce @aces(), # count aces as 1 when appropriate
      ((total, num) -> if total > 21 then total - 10 else total)
      totalWithAcesAsEleven

  bust: ->
    @value() > 21

  blackjack: ->
    @value() == 21

Blackjack.Game = Backbone.Model.extend
  initialize: ->
    console.log 'Game'
    Blackjack.Events.on "bj:gameOver", @finish, @

    @wager = 10
    @deck = new Blackjack.Deck
    @dealerHand = new Blackjack.Hand(@deck.deal(2))
    @dealerHandView = new Blackjack.DealerHandView(model: @dealerHand)
    @playerHand = new Blackjack.Hand(@deck.deal(2))
    @playerHandView = new Blackjack.PlayerHandView(model: @playerHand)
    @notificationView = new Blackjack.NotificationView

    @dealerHandView.render()
    @playerHandView.render()

    Blackjack.Events.trigger("bj:gameOver") if @playerHand.blackjack()

  winnings: ->
    switch @terminalEvent()
      when 'bj:player:blackjack' then @wager * 2
      when 'bj:dealer:bust', 'bj:player:wins' then @wager
      when 'bj:player:bust', 'bj:dealer:blackjack', 'bj:dealer:wins' then @wager * -1

  terminalEvent: ->
    switch
      when @playerHand.blackjack() then 'bj:player:blackjack'
      when @playerHand.bust() then 'bj:player:bust'
      when @dealerHand.blackjack() then 'bj:dealer:blackjack'
      when @dealerHand.bust() then 'bj:dealer:bust'
      when @dealerHand.value() < @playerHand.value() then 'bj:player:wins'
      else 'bj:dealer:wins' # dealer wins ties

  showDealerHand: ->
    @dealerHandView.cards(1).set('visible', true)
    @dealerHandView.render()

  adjustPlayerBalance: ->
    console.log ('winnings')
    Blackjack.Session.balance += @winnings()

  restart: ->
    # @notificationView.$el.slideUp('slow')
    # @notificationView.remove()
    # Blackjack.Session.dealGame()

  finish: ->
    Blackjack.Events.trigger(@terminalEvent())
    @showDealerHand()
    @adjustPlayerBalance()
    debugger
    # Blackjack.Session.redealGame()
    # @notificationView.$el.slideUp('slow')
    # @notificationView.remove()
    # Blackjack.Session.dealGame()        

# -----------------------------------------------------------------------------
# Views
# -----------------------------------------------------------------------------
Blackjack.NotificationView = Backbone.View.extend
  initialize: ->
    Blackjack.Events.on "bj:player:bust", @callbacks.player.bust, @
    Blackjack.Events.on "bj:dealer:bust", @callbacks.dealer.bust, @
    Blackjack.Events.on "bj:dealer:blackjack", @callbacks.dealer.blackjack, @
    Blackjack.Events.on "bj:player:blackjack", @callbacks.player.blackjack, @
    Blackjack.Events.on "bj:player:wins", @callbacks.player.wins, @
    Blackjack.Events.on "bj:dealer:wins", @callbacks.dealer.wins, @

  template: "<div id=notification class='<%= type %>'><%= message %></div>"

  callbacks:
    dealer:
      wins: -> @render(message: "Too bad! You lose", type: "lose")
      bust: -> @render(message: "You win! Dealer busted.", type: "win")
      blackjack: -> @render(message: "You lost! Dealer got blackjack.", type: "lose")
    player:
      wins: -> @render(message: "Hooray! You win.", type: "win")
      bust: -> @render(message: "You lose! You busted.", type: "lose")
      blackjack: -> @render(message: "You win! Black-motherfuckin-jack!", type: "win")

  render: (data) ->
    $('header').after(_.template(@template, data)).hide().slideDown()
    return this

Blackjack.CardView = Backbone.View.extend
  template: """
    <div class="card <%= suit %> <%= visibility %>">
      <div class=top_left>
        <div class=name><%= name %></div>
        <div class=suit><%= entityForSuit %></div>
      </div>
      <div class=bottom_right>
        <div class=name><%= name %></div>
        <div class=suit><%= entityForSuit %></div>
      </div>
    </div>
  """

  templateData: ->
    template = @model.toJSON()
    template.entityForSuit = @model.entityForSuit()
    template.visibility = if @model.get('visible') then 'visible' else 'hidden'
    template

  render: ->
    @$el.append _.template(@template, @templateData())
    return this

Blackjack.HandView = Backbone.View.extend
  cards: (index) ->
    @model.cards(index)

  templateData: ->
    template = @model.toJSON()
    template.value = @model.value()
    template

  render: ->
    @$el.html _.template(@template, @templateData())
    for card in @cards()
      new Blackjack.CardView(model: card, el: @$el.find(' .cards')).render()
    return this

Blackjack.PlayerHandView = Blackjack.HandView.extend
  initialize: ->
    @listenTo(@model, "add", @render)

  el: "#player"

  template: """
    <div class="hand player">
      <div class=value>Hand Total: <%= value %></div>
      <div class=cards></div>

      <div class=buttons>
        <a class=button id=hit>Hit</a>
        <a class=button id=stand>Stand</a>
      </div>
    </div>
  """

  events:
    "click #hit": 'hit'
    "click #stand": 'stand'

  hit: (event) ->
    event.preventDefault()
    @model.hit()
    Blackjack.Events.trigger("bj:gameOver") if @model.bust() || @model.blackjack()

  stand: (event) ->
    event.preventDefault()
    Blackjack.Events.trigger("bj:player:stand")

Blackjack.DealerHandView = Blackjack.HandView.extend
  initialize: ->
    @listenTo(@model, "add", @render)
    Blackjack.Events.on "bj:player:stand", @play, @
    @cards(1).set('visible', false)

  el: "#dealer"

  template: """
    <div class="hand dealer">
      <div class=cards></div>
    </div>
  """

  play: ->
    @model.hit() while @model.value() < 16
    Blackjack.Events.trigger("bj:gameOver")

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------
Blackjack.Session =
  balance: 1000

  dealGame: ->
    Blackjack.Session.currentGame = new Blackjack.Game
  
  redealGame: ->
    # Blackjack.Session.currentGame = new Blackjack.Game
  
  start: ->
    Blackjack.Session.dealGame()

jQuery ->
  Blackjack.Session.start()
  window.bj = Blackjack

