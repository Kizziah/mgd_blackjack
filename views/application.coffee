# TODO
# * Click event should not be in doc ready block
# * Is this a hack or good? `@$el.find('.card').remove()`

# -----------------------------------------------------------------------------
# Models
# -----------------------------------------------------------------------------
Card = Backbone.Model.extend
  defaults:
    suit: null
    name: null
    hidden: false

  entityForSuit: ->
    "&#{@get('suit')};" # e.g. "&hearts;"

  forTemplate: ->
    template = @toJSON()
    template.entityForSuit = @entityForSuit()
    template.visiblityClass = @visiblityClass()
    template

  visiblityClass: ->
    if @get('hidden') then 'flipped' else ''

  value: ->
    switch @get('name')
      when 'A' then 11
      when 'J', 'Q', 'K' then 10
      else parseInt(@get('name'))

Deck = Backbone.Collection.extend
  model: Card

  initialize: ->
    suits = ['hearts', 'clubs', 'spades', 'diams']
    names = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    for suit in suits
      for name in names
        @add({ suit: suit, name: name })
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


# -----------------------------------------------------------------------------
# Views
# -----------------------------------------------------------------------------
CardView = Backbone.View.extend
  template: """
    <div class="card <%= suit %> <%= visiblityClass %>">
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
    @setElement("##{@type()}_hand .cards") # e.g. "#player_hand .cards"
    @listenTo(@model, "add", @render)
    @setCardVisibility()

  setCardVisibility: ->
    @cards(1).set({ hidden: true }) if @type() == 'dealer'

  type: ->
    @options.type

  cards: (index) ->
    @model.cards(index)

  render: ->
    @$el.find('.card').remove()
    for card in @cards()
      new CardView(model: card, el: @el).render()
    return this


# -----------------------------------------------------------------------------
# Go!
# -----------------------------------------------------------------------------
jQuery ->

  window.deck = new Deck
  window.playerHand = new Hand(window.deck.deal(2))
  window.dealerHand = new Hand(window.deck.deal(2))

  window.playerHandView = new HandView
    model: window.playerHand
    type: 'player'

  window.dealerHandView = new HandView
    model: window.dealerHand
    type: 'dealer'

  window.playerHandView.render()
  window.dealerHandView.render()

  $('#hit').click (event) ->
    event.preventDefault()
    window.playerHand.hit(deck.deal(1))
