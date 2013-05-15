# -----------------------------------------------------------------------------
# Models
# -----------------------------------------------------------------------------
Card = Backbone.Model.extend
  defaults:
    suit: null
    name: null

  show: ->
    "#{@get('name')}#{@get('suit')}"

  value: ->
    switch @get('name')
      when 'A' then 11
      when 'J', 'Q', 'K' then 10
      else parseInt(@get('name'))

Deck = Backbone.Collection.extend
  model: Card

  initialize: ->
    suits = ['H', 'C', 'S', 'D']
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
    <div class="card">
      <%= name %><%= suit %>
    </div>
  """

  render: ->
    @$el.find('.cards').append _.template(@template, @model.toJSON())
    return this

HandView = Backbone.View.extend

  initialize: ->
    @listenTo(@model, "add", @render);

  render: ->
    @$el.find('.card').remove()
    for card in @model.cards()
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
    el: '#player_hand'

  window.dealerHandView = new HandView
    model: window.dealerHand
    el: '#dealer_hand'

  window.playerHandView.render()
  window.dealerHandView.render()

  $('#hit').click (event) ->
    event.preventDefault()
    window.playerHand.hit(deck.deal(1))
