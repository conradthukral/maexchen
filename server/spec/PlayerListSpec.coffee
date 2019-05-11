playerList = require '../lib/playerList'

describe 'PlayerList', ->

	describe 'permute', ->
		list1 = list2 = {}

		beforeEach ->
			jasmine.addMatchers
				toHaveEqualLength: ->
					compare: (actual, expected) ->
						passed = actual.length == expected.length
						result =
							pass: passed
							message: "Expected #{actual}#{' not' unless passed} to have same length as #{expected}"
						result

			list1 = playerList.empty()
			list2 = playerList.empty()
			for playerNumber in [1..100]
				player = name: playerNumber
				list1.add player
				list2.add player

		it 'should have same number of objects after permutation', ->
			expect(list1.players).toEqual(list2.players)
			list1.permute()
			expect(list1.players).toHaveEqualLength(list2.players)

		it 'should not have same order of objects after permutation', ->
			expect(list1.players).toEqual(list2.players)
			list1.permute()
			expect(list1.players).not.toEqual(list2.players)

