# TODO
# * We probably shouldn't need wrapper divs in index.html?

Blackjack = {}

# -----------------------------------------------------------------------------
# Events
# -----------------------------------------------------------------------------
Blackjack.Events = _.extend({}, Backbone.Events)


# -----------------------------------------------------------------------------
# Models
# -----------------------------------------------------------------------------
Blackjack.Card = Backbone.Model.extend

  entityForSuit: ->
    "&#{@get('suit')};" # e.g. "&hearts;"

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
    @add(Blackjack.Game.deck.deal(1))

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


# -----------------------------------------------------------------------------
# Views
# -----------------------------------------------------------------------------
Blackjack.NotificationView = Backbone.View.extend
  initialize: ->
    Blackjack.Events.on "bj:player:bust", @callbacks.player.bust, @
    Blackjack.Events.on "bj:dealer:bust", @callbacks.dealer.bust, @
    Blackjack.Events.on "bj:dealer:blackjack", @callbacks.player.blackjack, @
    Blackjack.Events.on "bj:player:blackjack", @callbacks.player.blackjack, @

  template: "<div class='message <%= type %>'><%= message %></div>"

  el: "#notification"

  callbacks:
    dealer:
      bust: -> @render(message: "You win! Dealer busted!", type: "win")
      blackjack: -> @render(message: "You lost! Dealer got blackjack!", type: "lose")
    player:
      bust: -> @render(message: "You lose! Looks like you busted!", type: "lose")
      blackjack: -> @render(message: "You win! Looks like you got blackjack!", type: "win")

  render: (data) ->
    @$el.html(_.template(@template, data)).hide().slideDown()
    return this

Blackjack.CardView = Backbone.View.extend
  template: """
    <div class="card <%= suit %>">
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
    template

  render: ->
    @$el.append _.template(@template, @templateData())
    return this

Blackjack.HandView = Backbone.View.extend
  cards: (index) ->
    @model.cards(index)

  triggerEvents: ->
    Blackjack.Events.trigger("bj:#{@type}:bust") if @model.bust()
    Blackjack.Events.trigger("bj:#{@type}:blackjack") if @model.blackjack()

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
      <div class=clear></div>
      <a class=button id=hit>Hit</a>
      <a class=button id=stand>Stand</a>
    </div>
  """

  type: "player"

  events:
    "click #hit": 'hit'
    "click #stand": 'stand'

  hit: (event) ->
    event.preventDefault()
    @model.hit()
    @triggerEvents()

  stand: (event) ->
    event.preventDefault()
    Blackjack.Events.trigger("bj:player:stand")

Blackjack.DealerHandView = Blackjack.HandView.extend
  initialize: ->
    @listenTo(@model, "add", @render)
    Blackjack.Events.on "bj:player:stand", @play, @

  el: "#dealer"

  template: """
    <div class="hand dealer">
      <div class=cards></div>
      <div class=clear></div>
    </div>
  """

  type: "dealer"

  play: ->
    @model.hit() while @model.value() < 16
    @triggerEvents()

Blackjack.Game =
  deck: new Blackjack.Deck

  play: ->
    dealerHand = new Blackjack.Hand(Blackjack.Game.deck.deal(2))
    new Blackjack.DealerHandView(model: dealerHand).render()

    playerHand = new Blackjack.Hand(Blackjack.Game.deck.deal(2))
    new Blackjack.PlayerHandView(model: playerHand).render()

    new Blackjack.NotificationView

# -----------------------------------------------------------------------------
# Go!
# -----------------------------------------------------------------------------
jQuery ->
  Blackjack.Game.play()
  window.bj = Blackjack

