require "lakebed"

RSpec.describe "sm" do
  before do
    load_module("sm").start
    kernel.continue
  end
  
  it "reaches startup without crashing" do
  end

  def connect
    session = nil
    kernel.named_ports["sm:"].client.connect do |sess|
      session = Lakebed::CMIF::ClientSessionObject.new(sess)
    end
    kernel.continue

    expect(session).not_to be_nil

    session
  end
  
  it "accepts connections to sm:" do
    connect
  end

  it "responds to Initialize" do
    session = connect
    session.send_message_sync(
      kernel,
      Lakebed::CMIF::Message.build_rq(0) do
        pid 0
      end).unpack do
    end
  end

  describe "without initialization" do
    if StratosphereHelpers.environment.is_ams? ||
       StratosphereHelpers.environment.target_firmware.numeric >= 201392178 then
      # no smhax
      it "replies to GetService with 0x415" do
        session = connect
        expect(
          session.send_message_sync(
            kernel,
            Lakebed::CMIF::Message.build_rq(1) do
              u64("fsp-srv\x00".unpack("Q<")[0])
            end)).to reply_with_error(0x415)
      end
    else
      it "does not reply to GetService for a service that has not been registered" do
        session = connect
        session.send_message(
          Lakebed::CMIF::Message.build_rq(1) do
            u64("fsp-srv\x00".unpack("Q<")[0])
          end) do
          fail "should not reply..."
        end
        kernel.continue
      end
    end
  end

  #it "replies to GetService for sm:m" do
  #  session = connect
  #  expect(
  #    session.send_message_sync(
  #      kernel,
  #      Lakebed::CMIF::Message.build_rq(1) do
  #        u64("sm:m\x00\x00\x00\x00".unpack("Q<")[0])
  #      end))
  #end
end
