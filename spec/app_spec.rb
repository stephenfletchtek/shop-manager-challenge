require_relative '../app'

def reset_tables
  seed_sql = File.read('spec/seeds_items_orders.sql')
  connection = PG.connect({ host: '127.0.0.1', dbname: 'shop_manager_test' })
  connection.exec(seed_sql)
end

def run_app(io)
  app = Application.new(
      'shop_manager_test',
      io,
      ItemRepository.new,
      OrderRepository.new
    )  
  app.run
end

describe Application do
  before(:each) do 
    reset_tables
  end

  it "lists all shop items" do
    str = "What do you want to do?\n"
    str += "  1 = list all shop items\n  2 = create a new item\n"
    str += "  3 = list all orders\n  4 = create a new order\n"
    io = double :fake
    expect(io).to receive(:puts).with(str)
    expect(io).to receive(:gets).and_return("1")
    expect(io).to receive(:puts).with("\nHere's a list of all shop items:\n\n")
    expect(io).to receive(:puts).with("#1 - Hoover - Unit price: 100 - Quantity: 20")
    expect(io).to receive(:puts).with("#2 - Washing Machine - Unit price: 400 - Quantity: 30")
    expect(io).to receive(:puts).with("#3 - Cooker - Unit price: 389 - Quantity: 12")
    expect(io).to receive(:puts).with("#4 - Tumble Dryer - Unit price: 279 - Quantity: 44")
    expect(io).to receive(:puts).with("#5 - Fridge - Unit price: 199 - Quantity: 15")  

    run_app(io)
  end

  it "creates a new item" do
    str = "What do you want to do?\n"
    str += "  1 = list all shop items\n  2 = create a new item\n"
    str += "  3 = list all orders\n  4 = create a new order\n"
    io = double :fake
    expect(io).to receive(:puts).with(str)
    expect(io).to receive(:gets).and_return("2")
    expect(io).to receive(:puts).with("\nEnter item name:")
    expect(io).to receive(:gets).and_return("Freezer")
    expect(io).to receive(:puts).with("\nEnter unit price:")
    expect(io).to receive(:gets).and_return("289")
    expect(io).to receive(:puts).with("\nEnter stock quantity:")
    expect(io).to receive(:gets).and_return("150")
    expect(io).to receive(:puts).with("\n Create item: <Freezer - 289 - 150>? [Y/n]")
    expect(io).to receive(:gets).and_return("Y")

    run_app(io)

    repo = ItemRepository.new
    new_item = repo.all[-1]
    expect(new_item.name).to eq 'Freezer'
    expect(new_item.unit_price).to eq '289'
    expect(new_item.qty).to eq '150'
  end

  it "lists all orders" do
    str = "What do you want to do?\n"
    str += "  1 = list all shop items\n  2 = create a new item\n"
    str += "  3 = list all orders\n  4 = create a new order\n"

    ord = "\nHere's a list of all orders:\n\n"
    ord += "  #1 - Customer: Frank - Placed: 04-Jan-2021\n"
    ord += "    * Hoover - Unit price: 100 - qty: 2\n"
    ord += "    * Washing Machine - Unit price: 400 - qty: 1\n"
    ord += "  #2 - Customer: Benny - Placed: 05-Aug-2022\n"
    ord += "    * Hoover - Unit price: 100 - qty: 1\n"
    ord += "    * Cooker - Unit price: 389 - qty: 3\n"

    io = double :fake
    expect(io).to receive(:puts).with(str)
    expect(io).to receive(:gets).and_return("3")    
    expect(io).to receive(:puts).with(ord)  

    run_app(io)
  end

  it "creates an order" do
    str = "What do you want to do?\n"
    str += "  1 = list all shop items\n  2 = create a new item\n"
    str += "  3 = list all orders\n  4 = create a new order\n"

    io = double :fake
    expect(io).to receive(:puts).with(str)
    expect(io).to receive(:gets).and_return("4")    
    expect(io).to receive(:puts).with("\nWho is ordering?")
    expect(io).to receive(:gets).and_return("Wendy")    
    expect(io).to receive(:puts).with("\nEnter <item name>, <qty> to add to order")
    expect(io).to receive(:puts).with("Type 'Y' when done")
    expect(io).to receive(:gets).and_return("Cooker, 1")
    expect(io).to receive(:puts).with("Add <Cooker - 1> to order? [Y/n]")
    expect(io).to receive(:gets).and_return("Y")
    expect(io).to receive(:puts).with("\nEnter <item name>, <qty> to add to order")
    expect(io).to receive(:puts).with("Type 'Y' when done")
    expect(io).to receive(:gets).and_return("Y")
    expect(io).to receive(:puts).with("\nOrder summary:")
    expect(io).to receive(:puts).with("* Cooker - qty: 1")
    expect(io).to receive(:puts).with("\nProceed? [Y/n]")
    expect(io).to receive(:gets).and_return("Y")
    expect(io).to receive(:puts).with("\nOrder placed!")

    run_app(io)

    order_repo = OrderRepository.new
    new_order = order_repo.all[-1]
    with_items = order_repo.order_with_items(new_order.id)
    expect(new_order.customer_name).to eq 'Wendy'
    expect(with_items.items[0].name).to eq 'Cooker'
    item_repo = ItemRepository.new
    cooker = item_repo.find_item(3)
    expect(cooker.qty).to eq '11'
  end

  it "cancels an order" do
    str = "What do you want to do?\n"
    str += "  1 = list all shop items\n  2 = create a new item\n"
    str += "  3 = list all orders\n  4 = create a new order\n"

    io = double :fake
    expect(io).to receive(:puts).with(str)
    expect(io).to receive(:gets).and_return("4")    
    expect(io).to receive(:puts).with("\nWho is ordering?")
    expect(io).to receive(:gets).and_return("Bill")    
    expect(io).to receive(:puts).with("\nEnter <item name>, <qty> to add to order")
    expect(io).to receive(:puts).with("Type 'Y' when done")
    expect(io).to receive(:gets).and_return("Y")
    expect(io).to receive(:puts).with("\nOrder summary:")
    expect(io).to receive(:puts).with("\nProceed? [Y/n]")
    expect(io).to receive(:gets).and_return("n")
    expect(io).to receive(:puts).with("\nOrder cancelled!")

    run_app(io)

    order_repo = OrderRepository.new
    orders = order_repo.all
    expect(orders.length).to eq 2
  end
end
