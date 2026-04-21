-- Automated Auction Ending System
-- Run this in the Supabase SQL Editor as the `postgres` role.

begin;

-- ===========================================
-- 1. Function to automatically finalize auctions
-- ===========================================
create or replace function public.auto_finalize_expired_auctions()
returns table (
  auction_id uuid,
  winner_user_id uuid,
  winning_bid numeric,
  invoice_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  expired_auction record;
  winner_bid record;
  new_invoice_id uuid;
begin
  -- Find all expired auctions that haven't been finalized yet
  for expired_auction in
    select a.id, a.title, a.current_bid, a.status
    from auctions a
    where a.end_time < now()
      and a.status not in ('finalized', 'cancelled', 'ended')
      and a.current_bid > 0
  loop
    -- Find the winning bid (highest bid for this auction)
    select b.user_id, b.amount
    into winner_bid
    from bids b
    where b.auction_id = expired_auction.id
    order by b.amount desc, b.created_at asc
    limit 1;

    if winner_bid.user_id is not null then
      -- Create invoice for the winner
      insert into invoices (
        auction_id,
        user_id,
        amount,
        status,
        description,
        created_at
      ) values (
        expired_auction.id,
        winner_bid.user_id,
        winner_bid.amount,
        'pending',
        'Winning bid for auction: ' || expired_auction.title,
        now()
      ) returning id into new_invoice_id;

      -- Update auction status to finalized
      update auctions
      set status = 'finalized'
      where id = expired_auction.id;

      -- Mark the winning bid
      update bids
      set is_winner = true
      where auction_id = expired_auction.id
        and user_id = winner_bid.user_id
        and amount = winner_bid.amount
        and created_at = (
          select min(created_at)
          from bids
          where auction_id = expired_auction.id
            and user_id = winner_bid.user_id
            and amount = winner_bid.amount
        );

      -- Return the finalized auction info
      auction_id := expired_auction.id;
      winner_user_id := winner_bid.user_id;
      winning_bid := winner_bid.amount;
      invoice_id := new_invoice_id;

      return next;
    end if;
  end loop;

  return;
end;
$$;

-- ===========================================
-- 2. Function to notify participants when auction ends
-- ===========================================
create or replace function public.notify_auction_ended(
  p_auction_id uuid,
  p_winner_user_id uuid,
  p_winning_bid numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  auction_record record;
  participant_record record;
begin
  -- Get auction details
  select title, category from auctions where id = p_auction_id into auction_record;

  -- Notify all bidders about the auction ending
  for participant_record in
    select distinct b.user_id, p.display_name
    from bids b
    join profiles p on p.id = b.user_id
    where b.auction_id = p_auction_id
  loop
    -- Create notification for each participant
    insert into notifications (
      user_id,
      title,
      body,
      type,
      entity_type,
      entity_id
    ) values (
      participant_record.user_id,
      'Auction Ended',
      case
        when participant_record.user_id = p_winner_user_id
        then 'Congratulations! You won the auction for ' || auction_record.title || ' with a bid of EGP ' || p_winning_bid::text
        else 'The auction for ' || auction_record.title || ' has ended. Better luck next time!'
      end,
      'auction_ended',
      'auction',
      p_auction_id
    );
  end loop;
end;
$$;

-- ===========================================
-- 3. Scheduled function to check for expired auctions
-- ===========================================
create or replace function public.check_expired_auctions()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  finalized_record record;
begin
  -- Auto-finalize expired auctions and get results
  for finalized_record in
    select * from auto_finalize_expired_auctions()
  loop
    -- Send notifications for each finalized auction
    perform notify_auction_ended(
      finalized_record.auction_id,
      finalized_record.winner_user_id,
      finalized_record.winning_bid
    );
  end loop;
end;
$$;

-- ===========================================
-- 4. Create a cron job trigger (runs every 5 minutes)
-- ===========================================
-- Note: This requires pg_cron extension to be enabled in Supabase
-- You may need to enable it in your Supabase project settings

-- Uncomment the following lines if pg_cron is available:
-- select cron.schedule(
--   'check-expired-auctions',
--   '*/5 * * * *', -- Every 5 minutes
--   'select check_expired_auctions();'
-- );

-- ===========================================
-- 5. Alternative: Manual trigger for development/testing
-- ===========================================
-- You can call this function manually or set up a cron job externally
-- Example: select check_expired_auctions();

commit;