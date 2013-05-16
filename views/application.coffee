# TODO
# * Is this a hack or good? `@$el.find('.card').remove()`
# * Hand view should be roped into the JS in order to support more than one player hand

# -----------------------------------------------------------------------------
# Models
# -----------------------------------------------------------------------------
Card = Backbone.Model.extend
  defaults:
    suit: null
    name: null

  entityForSuit: ->
    "&#{@get('suit')};" # e.g. "&hearts;"

  forTemplate: ->
    template = @toJSON()
    template.entityForSuit = @entityForSuit()
    template

  isAce: ->
    @get('name') == 'A'

  value: ->
    switch @get('name')
      when 'A' then 11 # assume 11 but could be 1 depending on hand
      when 'J', 'Q', 'K' then 10
      else parseInt(@get('name'))

Deck = Backbone.Collection.extend
  model: Card

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

Hand = Backbone.Collection.extend
  model: Card

  cards: (index) ->
    if index then @models[index-1] else @models

  hit: (card) ->
    @add(card)
    console.log @value()

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
CardView = Backbone.View.extend
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

  render: ->
    @$el.append _.template(@template, @model.forTemplate())
    return this


HandView = Backbone.View.extend

  initialize: ->
    @listenTo(@model, "add", @render)

  cards: (index) ->
    @model.cards(index)

  render: ->
    @$el.html _.template(@template, {})
    for card in @cards()
      new CardView(model: card, el: @$el.find(' .cards')).render()
    return this


PlayerHandView = HandView.extend
  el: "#player"

  template: """
    <div class="hand player">
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
    @model.hit(Blackjack.deck.deal(1))

  stand: (event) ->
    event.preventDefault()
    console.log 'Stand!'


DealerHandView = HandView.extend
  el: "#dealer"

  template: """
    <div class="hand dealer">
      <div class=cards></div>
      <div class=clear></div>
    </div>
  """


Blackjack =
  deck: new Deck

  play: ->
    dealerHand = new Hand(Blackjack.deck.deal(2))
    new DealerHandView(model: dealerHand).render()

    playerHand = new Hand(Blackjack.deck.deal(2))
    new PlayerHandView(model: playerHand).render()


# -----------------------------------------------------------------------------
# Go!
# -----------------------------------------------------------------------------
jQuery -> Blackjack.play()
