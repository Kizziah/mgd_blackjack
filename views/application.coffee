# TODO
# * Hand view should be roped into the JS in order to support more than one player hand

# -----------------------------------------------------------------------------
# Models
# -----------------------------------------------------------------------------
Blackjack = {}

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

  hit: (card) ->
    @add(card)

  aces: ->
    @cards().filter (card) -> card.isAce()

  value: ->
    values = @cards().map (card) -> card.value()
    totalWitAcesAsEleven = _.reduce(values, ((memo, num) -> memo + num), 0)
    _.reduce @aces(), ((memo, num) -> memo - 10 if memo > 21), totalWitAcesAsEleven

  bust: ->
    @value() > 21

  blackjack: ->
    @value() == 21


# -----------------------------------------------------------------------------
# Views
# -----------------------------------------------------------------------------
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

  initialize: ->
    @listenTo(@model, "add", @render)

  cards: (index) ->
    @model.cards(index)

  showBust: ->
    $('.notification.bust').show()

  showBlackjack: ->
    $('.notification.blackjack').show()

  render: ->
    @$el.html _.template(@template, {})

    @showBlackjack() if @model.blackjack()
    @showBust() if @model.bust()

    for card in @cards()
      new Blackjack.CardView(model: card, el: @$el.find(' .cards')).render()
    return this

Blackjack.PlayerHandView = Blackjack.HandView.extend
  el: "#player"

  template: """
    <div class="hand player">

      <div class="bust notification">Oh no! You busted.</div>
      <div class="blackjack notification">Congrats! You got blackjack.</div>

      <div class=cards></div>
      <div class=clear></div>
      <a class=button id=hit>Hit</a>
      <a class=button id=stand>Stand</a>
    </div>
  """

  events:
    "click #hit": 'hit'
    "click #stand": 'stand'

  hit: (event) ->
    event.preventDefault()
    @model.hit(Blackjack.Game.deck.deal(1))

  stand: (event) ->
    event.preventDefault()
    console.log 'Stand!'

Blackjack.DealerHandView = Blackjack.HandView.extend
  el: "#dealer"

  template: """
    <div class="hand dealer">
      <div class=cards></div>
      <div class=clear></div>
    </div>
  """

Blackjack.Game =
  deck: new Blackjack.Deck

  play: ->
    dealerHand = new Blackjack.Hand(Blackjack.Game.deck.deal(2))
    new Blackjack.DealerHandView(model: dealerHand).render()

    playerHand = new Blackjack.Hand(Blackjack.Game.deck.deal(2))
    new Blackjack.PlayerHandView(model: playerHand).render()


# -----------------------------------------------------------------------------
# Go!
# -----------------------------------------------------------------------------
jQuery ->
  Blackjack.Game.play()
