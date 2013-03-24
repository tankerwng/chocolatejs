unless window?
    Reserve = require '../server/reserve'
    Uuid = require '../general/intentware/uuid'
    Data = require '../general/intentware/data'

    describe 'Reserve', ->
        describe 'Space', ->
            space = undefined
            
            it 'should create a Space', ->
                expect(space = new Reserve.Space(jasmine.getEnv().ijax.datadir, 'reserve.spec.db')).not.toBeUndefined()
                expect(space instanceof Reserve.Space).toBeTruthy()
            describe 'Path', ->
                it 'should get an index from an int', ->
                    expect(Reserve.Space.Path.Address.from_int(4294967296).toString()).toEqual((new Buffer [0, 0, 1, 0, 0, 0, 0]).toString())
                it 'should get an int from an index', ->
                    expect(Reserve.Space.Path.Address.to_int(new Buffer [0, 0, 1, 0, 0, 0, 0])).toEqual(4294967296)
                it 'should be able to append a buffer address to a path', ->
                    expect(Reserve.Space.Path.append(new Buffer([0, 0, 1, 0, 0, 0, 0]), new Buffer([0, 0, 0, 0, 0, 1, 0])).toString('hex')).toEqual((new Buffer [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0]).toString('hex'))
                it 'should be able to append an int address to a path', ->
                    expect(Reserve.Space.Path.append(new Buffer([0, 0, 1, 0, 0, 0, 0]), 256).toString('hex')).toEqual((new Buffer [0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0]).toString('hex'))
                it 'should give next address when we provide one', ->
                    expect(Reserve.Space.Path.next(new Buffer [0, 0, 1, 0, 0, 0, 255]).toString('hex')).toEqual((new Buffer [0, 0, 1, 0, 0, 1, 0]).toString('hex'))

            describe 'JS', ->

                Todo = class
                    constructor: (@title, @parent, @dimensions, @uuid = Uuid()) ->
                        @subs = []
                        @test_data =
                            boolean: yes
                            number: 1.23
                        @date =
                            creation: new Date()
                            modified: new Date()
                dimensions = 
                    Action: "Do"
                    Intention: "Make"
                    Need: "No need"
                    Priority: "Now"
                    Scope: "Me"
                    Share: "No share"
                    Wish: "No wish"

                todo = new Todo 'todo', null, dimensions

                it 'should returns null when reading non-existent container', ->
                    result = undefined
                    runs -> space.read 1, (error, data) -> result = {data}
                    waitsFor (-> result?), 'space.read(1)', 1000
                    runs -> expect(result.data).toBe null

                it 'should save a JS Object', ->
                    result = undefined
                    runs -> space.write todo, (error) -> result = {error}
                    waitsFor (-> result?), 'space.write(todo)', 1000
                    runs -> expect(result.error).toBe null

                it 'should send an error when saving the same JS Object', ->
                    result = undefined
                    runs -> space.write todo, (error) -> result = {error}
                    waitsFor (-> result?), 'space.write(todo)', 1000
                    runs -> expect(result.error).not.toBe null

                it 'should save a new JS Object', ->
                    result = undefined
                    runs -> 
                        todo = new Todo 'new_todo', null, dimensions
                        space.write todo, (error) -> result = {error}
                    waitsFor (-> result?), 'space.write(todo)', 1000
                    runs -> expect(result.error).toBe null

                it 'should read a JS Object from database', ->
                    result = undefined
                    runs -> space.read todo.uuid, (error, data) -> result = {data}
                    waitsFor (-> result?), 'space.read(todo.uuid)', 1000
                    runs ->
                        expect(result.data).not.toBe null
                        new_todo = result.data
                        expect(new_todo.title).toBe 'new_todo'

                it 'should destroy an Object from database', ->
                    result = undefined
                    runs -> space.forget todo, (error) -> result = {error}
                    waitsFor (-> result?), 'Reserve.space.forget(todo)', 1000
                    runs -> expect(result.error).toBe null

                it 'should returns null when reading removed container', ->
                    result = undefined
                    runs -> space.read todo.uuid, (error, data) -> result = {data}
                    waitsFor (-> result?), 'space.read(1)', 1000
                    runs -> expect(result.data).toBe null

            describe 'end', ->
                it 'should delete Space db file', ->
                    expect(-> require('fs').unlinkSync space.db_path).not.toThrow()
